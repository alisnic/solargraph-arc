require 'solargraph'
require 'active_support/core_ext/string/inflections'
require 'pry'

class Walker
  class Hook
    attr_reader :args, :proc, :node_type
    def initialize(node_type, args, &block)
      @node_type = node_type
      @args = args
      @proc = Proc.new(&block)
    end
  end

  def initialize(ast)
    @ast   = ast
    @hooks = Hash.new([])
  end

  def on(node_type, args, &block)
    @hooks[node_type] << Hook.new(node_type, args, &block)
  end

  def walk
    if @ast.is_a?(Array)
      @ast.each { |node| traverse(node) }
    else
      traverse(@ast)
    end
  end

  private

  def traverse(node)
    return unless node.is_a?(Parser::AST::Node)

    @hooks[node.type].each do |hook|
      try_match(node, hook)
    end

    node.children.each {|child| traverse(child) }
  end

  def try_match(node, hook)
    return unless node.type == hook.node_type
    return unless node.children

    matched = node.children.any? do |child|
      next unless child.is_a?(Parser::AST::Node)
      next unless child.type == hook.args.first
      hook.args[1..-1].each_with_index.all? { |arg, i| child.children[i] == arg }
    end

    if matched
      if hook.proc.arity == 1
        hook.proc.call(node)
      elsif hook.proc.arity == 2
        walker = Walker.new(node)
        hook.proc.call(node, walker)
        walker.walk
      end
    end
  end
end

class SolarRails < Solargraph::Convention::Base
  RUBY_TYPES = {
    decimal: 'BigDecimal',
    integer: 'Integer',
    date: 'Date',
    datetime: 'ActiveSupport::TimeWithZone',
    string: 'String',
    boolean: 'Boolean',
    text: 'String',
    jsonb: 'Hash',
    bigint: 'Integer',
    inet: 'IPAddr'
  }

  def local source_map
    if source_map.filename.include?("app/models")
      Solargraph::Environ.new(pins: model_pins(source_map))
      # pp model_pins(source_map)
      # EMPTY_ENVIRON
    else
      EMPTY_ENVIRON
    end
  end

  private

  def model_pins(source_map)
    ns         = source_map.document_symbols.find {|s| s.is_a?(Solargraph::Pin::Namespace) }
    table_name = infer_table_name(ns)
    table      = schema[table_name]

    return [] unless table

    table.map do |column, type|
      # TODO: get location data from db/schema.rb
      location = Solargraph::Location.new(
        "db/schema.rb",
        Solargraph::Range.from_to(
          0,
          0,
          0,
          0
        )
      )

      Solargraph::Pin::Method.new(
        name:      column,
        comments:  "@return [#{RUBY_TYPES.fetch(type.to_sym)}]",
        location:  location,
        closure:   ns,
        scope:     :instance,
        attribute: true
      )
    end
  end

  # TODO: support custom table names, by parsing `self.table_name = ` invokations
  # inside model
  def infer_table_name(ns)
    ns.name.underscore.pluralize
  end

  def build_method_definition
    Solargraph::Pin::Method.new(
      name: attr[:name],
      comments: "@return [#{type_translation.fetch(attr[:type], attr[:type])}]",
      location: attr[:location],
      closure: Solargraph::Pin::Namespace.new(name: module_names.join('::') + "::#{model_name}"),
      scope: :instance,
      attribute: true
    )
  end

  def schema
    @extracted_schema ||= begin
      ast = Solargraph::Parser.parse_with_comments(File.read("db/schema.rb"), "db/schema.rb")
      extract_schema(ast)
    end
  end

  def extract_schema(ast)
    schema = {}

    walker = Walker.new(ast)
    walker.on :block, [:send, nil, :create_table] do |ast, query|
      table_name = ast.children.first.children[2].children.last
      schema[table_name] = {}

      query.on :send, [:lvar, :t] do |column_ast|
        name = column_ast.children[2].children.last
        type = column_ast.children[1]

        next if type == :index
        schema[table_name][name] = type
      end
    end

    walker.walk
    schema
  end
end

Solargraph::Convention.register SolarRails
