module SolarRails
  module Util
    def self.build_public_method(ns, name, types: nil, location:, attribute: false)
      opts = {
        name:      name,
        location:  location,
        closure:   ns,
        scope:     :instance,
        attribute: attribute
      }
      opts[:comments] = "@return [#{types.join(',')}]" if types

      Solargraph::Pin::Method.new(opts)
    end

    def self.build_module_include(ns, module_name, location)
      Solargraph::Pin::Reference::Include.new(
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
