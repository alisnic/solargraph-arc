module Solargraph
  module Arc
    class Devise
      def self.instance
        @instance ||= self.new
      end

      def initialize
        @seen_devise_closures = []
      end

      def process(source_map, ns)
        if source_map.filename.include?("app/models")
          process_model(source_map, ns)
        elsif source_map.filename.end_with?("app/controllers/application_controller.rb")
          process_controller(source_map, ns)
        else
          []
        end
      end

      private

      def process_model(source_map, ns)
        walker = Walker.from_source(source_map.source)
        pins   = []

        walker.on :send, [nil, :devise] do |ast|
          @seen_devise_closures << ns

          modules = ast.children[2..-1]
            .map {|c| c.children.first }
            .select {|s| s.is_a?(Symbol) }

          modules.each do |mod|
            pins << Util.build_module_include(
              ns,
              "Devise::Models::#{mod.to_s.capitalize}",
              Util.build_location(ast, ns.filename)
            )
          end
        end

        walker.walk
        pins
      end

      def process_controller(source_map, ns)
        pins = [
          Util.build_module_include(
            ns,
            "Devise::Controllers::Helpers",
            Util.dummy_location(ns.filename)
          )
        ]

        pins + @seen_devise_closures.map do |model_ns|
          ast = Walker.normalize_ast(source_map.source)
          mapping = model_ns.name.underscore

          [
            Util.build_public_method(
              ns,
              "authenticate_#{mapping}!",
              location: Util.build_location(ast, ns.filename)
            ),
            Util.build_public_method(
              ns,
              "#{mapping}_signed_in?",
              types: ["true", "false"],
              location: Util.build_location(ast, ns.filename)
            ),
            Util.build_public_method(
              ns,
              "current_#{mapping}",
              types: [model_ns.name, "nil"],
              location: Util.build_location(ast, ns.filename)
            ),
            Util.build_public_method(
              ns,
              "#{mapping}_session",
              location: Util.build_location(ast, ns.filename)
            )
          ]
        end.flatten
      end
    end
  end
end
