module Solargraph
  module Arc
    module Util
      def self.build_public_method(ns, name, types: nil, yieldtypes: nil, location: nil, attribute: false, scope: :instance)
        opts = {
          name:      name,
          location:  location,
          closure:   ns,
          scope:     scope,
          attribute: attribute
        }

        comments = []
        comments << "@return [#{types.join(',')}]" if types
        comments << "@yieldself [#{yieldtypes.join(',')}]" if yieldtypes

        opts[:comments] = comments.join("\n")

        Solargraph::Pin::Method.new(opts)
      end

      def self.build_module_include(ns, module_name, location)
        Solargraph::Pin::Reference::Include.new(
          closure:  ns,
          name:     module_name,
          location: location
        )
      end

      def self.build_module_extend(ns, module_name, location)
        Solargraph::Pin::Reference::Extend.new(
          closure:  ns,
          name:     module_name,
          location: location
        )
      end

      def self.dummy_location(path)
        Solargraph::Location.new(
          path,
          Solargraph::Range.from_to(0, 0, 0, 0)
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

      def self.method_return(path, type)
        Solargraph::Pin::Reference::Override.method_return(path, type)
      end
    end
  end
end
