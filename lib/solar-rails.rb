require 'solargraph'
require 'active_support/core_ext/string/inflections'

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

  def on(node_type, args=[], &block)
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

    matched = hook.args.empty? || if node.children.first.is_a?(Parser::AST::Node)
      node.children.any? { |child| child.is_a?(Parser::AST::Node) && match_children(hook.args[1..-1], child.children) }
    else
      match_children(hook.args, node.children)
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

  def match_children(args, children)
    args.each_with_index.all? do |arg, i|
      if children[i].is_a?(Parser::AST::Node)
        children[i].type == arg
      else
        children[i] == arg
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
      pins = model_pins(source_map)
      Solargraph::Environ.new(pins: pins)
    else
      EMPTY_ENVIRON
    end
  end

  private

  def model_pins(source_map)
    ns = source_map.document_symbols.find {|s| s.is_a?(Solargraph::Pin::Namespace) }
    schema_pins(ns) + relation_pins(source_map, ns)
  end

  def schema_pins(ns)
    table_name = infer_table_name(ns)
    table      = schema[table_name]

    return [] unless table

    table.map do |column, type|
      build_public_method(ns, column, RUBY_TYPES.fetch(type.to_sym))
    end
  end

  def build_public_method(ns, name, type, ast: nil, path: nil)
    location = if ast
      build_location(ast, path)
    else
      dummy_location
    end

    Solargraph::Pin::Method.new(
      name:      name,
      comments:  "@return [#{type}]",
      location:  location,
      closure:   ns,
      scope:     :instance,
      attribute: true
    )
  end

  def build_location(ast, path)
    Solargraph::Location.new(
      path,
      Solargraph::Range.from_to(
        ast.location.first_line,
        0,
        ast.location.last_line,
        ast.location.column
      )
    )
  end

  def dummy_location
    # TODO: get location data from db/schema.rb
    Solargraph::Location.new(
      "db/schema.rb",
      Solargraph::Range.from_to(
        0,
        0,
        0,
        0
      )
    )
  end

  def relation_pins(source_map, ns)
    ast    = source_map.source.node
    walker = Walker.new(ast)
    pins   = []

    walker.on :send, [nil, :belongs_to] do |ast|
      relation_name = ast.children[2].children.first

      # TODO: handle custom class for relation
      pins << build_public_method(
        ns,
        relation_name.to_s,
        relation_name.to_s.camelize,
        ast:  ast,
        path: ns.filename
      )
    end

    walker.on :send, [nil, :has_many] do |ast|
      relation_name = ast.children[2].children.first

      Solargraph.logger.debug("#{ns.name}: found has_many #{relation_name}")

      # TODO: handle custom class for relation
      pins << build_public_method(
        ns,
        relation_name.to_s,
        "ActiveRecord::Associations::CollectionProxy<#{relation_name.to_s.singularize.camelize}>",
        ast:  ast,
        path: ns.filename
      )
    end

    walker.walk
    pins
  end

  # TODO: support custom table names, by parsing `self.table_name = ` invokations
  # inside model
  def infer_table_name(ns)
    ns.name.underscore.pluralize
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

Solargraph::Convention.register SolarRails unless ENV["RAILS_ENV"] == "test"
