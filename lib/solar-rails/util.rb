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

    def self.method_return(path, type)
      Solargraph::Pin::Reference::Override.method_return(path, type)
    end
  end
end
