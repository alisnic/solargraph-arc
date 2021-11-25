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

module SolarRails
  module Util
    def self.build_public_method(ns, name, type, ast:, path:)
      location = build_location(ast, path)

      Solargraph::Pin::Method.new(
        name:      name,
        comments:  "@return [#{type}]",
        location:  location,
        closure:   ns,
        scope:     :instance,
        attribute: true
      )
    end

    def self.build_location(ast, path)
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
  end

  class Schema
    ColumnData = Struct.new(:type, :ast)

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

    def self.instance
      @instance ||= self.new
    end

    def process(source_map, ns)
      return [] unless source_map.filename.include?("app/models")

      table_name = infer_table_name(ns)
      table      = schema[table_name]

      return [] unless table

      table.map do |column, data|
        Util.build_public_method(
          ns,
          column,
          RUBY_TYPES.fetch(data.type.to_sym),
          ast:  data.ast,
          path: "db/schema.rb"
        )
      end
    end

    private

    def schema
      @extracted_schema ||= begin
        ast = Solargraph::Parser.parse_with_comments(File.read("db/schema.rb"), "db/schema.rb")
        extract_schema(ast)
      end
    end

    # TODO: support custom table names, by parsing `self.table_name = ` invokations
    # inside model
    def infer_table_name(ns)
      ns.name.underscore.pluralize
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
          schema[table_name][name] = ColumnData.new(type, column_ast)
        end
      end

      walker.walk
      schema
    end
  end

  class Relation
    def self.instance
      @instance ||= self.new
    end

    def process(source_map, ns)
      return [] unless source_map.filename.include?("app/models")

      ast    = source_map.source.node
      walker = Walker.new(ast)
      pins   = []

      walker.on :send, [nil, :belongs_to] do |ast|
        pins << singular_association(ns, ast)
      end

      walker.on :send, [nil, :has_one] do |ast|
        pins << singular_association(ns, ast)
      end

      walker.on :send, [nil, :has_many] do |ast|
        pins << plural_association(ns, ast)
      end

      walker.on :send, [nil, :has_and_belongs_to_many] do |ast|
        pins << plural_association(ns, ast)
      end

      walker.walk
      pins
    end

    # TODO: handle custom class for relation
    def plural_association(ns, ast)
      relation_name = ast.children[2].children.first

      Util.build_public_method(
        ns,
        relation_name.to_s,
        "ActiveRecord::Associations::CollectionProxy<#{relation_name.to_s.singularize.camelize}>",
        ast:  ast,
        path: ns.filename
      )
    end

    # TODO: handle custom class for relation
    def singular_association(ns, ast)
      relation_name = ast.children[2].children.first

      Util.build_public_method(
        ns,
        relation_name.to_s,
        relation_name.to_s.camelize,
        ast:  ast,
        path: ns.filename
      )
    end
  end

  class NamespaceHack
    def self.instance
      @instance ||= self.new
    end

    def process(source_map, ns, ds)
      return [] unless ds.size == 1 && ns.path.include?("::")
      root_ns = source_map.pins.find {|p| p.path == "" }
      namespace_stubs(root_ns, ns)
    end

    def namespace_stubs(root_ns, ns)
      parts = ns.path.split("::")

      candidates = parts.each_with_index.reduce([]) do |acc, (_, i)|
        acc + [parts[0..i].join("::")]
      end.reject {|el| el == ns.path }

      previous_ns = root_ns
      pins = []

      parts[0..-2].each_with_index do |name, i|
        gates = candidates[0..i].reverse + [""]
        path = gates.first
        next if path == ns.path

        previous_ns = Solargraph::Pin::Namespace.new(
          type:       :class,
          location:   ns.location,
          closure:    previous_ns,
          name:       name,
          comments:   ns.comments,
          visibility: :public,
          gates:      gates[1..-1]
        )

        pins << previous_ns
      end

      pins
    end
  end

  class Convention < Solargraph::Convention::Base
    def global yard_map
      ann = File.read(File.dirname(__FILE__) + "/annotations.rb")
      source = Solargraph::Source.load_string(ann, "annotations.rb")
      map = Solargraph::SourceMap.map(source)

      Solargraph::Environ.new(pins: map.pins)
    end

    def local source_map
      Solargraph.logger.debug("[Rails] process #{source_map.filename}")

      pins = []
      ds   = source_map.document_symbols.select {|n| n.is_a?(Solargraph::Pin::Namespace) }
      ns   = ds.first

      pins += Schema.instance.process(source_map, ns)
      pins += Relation.instance.process(source_map, ns)
      pins += NamespaceHack.instance.process(source_map, ns, ds)

      Solargraph::Environ.new(pins: pins)
    end
  end
end

Solargraph::Convention.register(SolarRails::Convention) unless ENV["RAILS_ENV"] == "test"
