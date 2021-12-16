module Solargraph
  module Arc
    class Walker
      class Hook
        attr_reader :args, :proc, :node_type
        def initialize(node_type, args, &block)
          @node_type = node_type
          @args = args
          @proc = Proc.new(&block)
        end
      end

      # https://github.com/castwide/solargraph/issues/522
      def self.normalize_ast(source)
        ast = source.node

        if ast.is_a?(::Parser::AST::Node)
          ast
        else
          NodeParser.parse(source.code, source.filename)
        end
      end

      def self.from_source(source)
        self.new(self.normalize_ast(source))
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
        return unless node.is_a?(::Parser::AST::Node)

        @hooks[node.type].each do |hook|
          try_match(node, hook)
        end

        node.children.each {|child| traverse(child) }
      end

      def try_match(node, hook)
        return unless node.type == hook.node_type
        return unless node.children

        matched = hook.args.empty? || if node.children.first.is_a?(::Parser::AST::Node)
          node.children.any? { |child| child.is_a?(::Parser::AST::Node) && match_children(hook.args[1..-1], child.children) }
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
          if children[i].is_a?(::Parser::AST::Node)
            children[i].type == arg
          else
            children[i] == arg
          end
        end
      end
    end
  end
end
