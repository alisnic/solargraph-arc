module Solargraph
  module Arc
    class Devise
      def self.instance
        @instance ||= self.new
      end

      def initialize
        @seen_devise_models = []
        @models_parsed = false
      end

      def process(source_map, ns)
        if source_map.filename.include?("app/models")
          @models_parsed = true
          process_model(source_map.source, ns)
        elsif source_map.filename.end_with?("app/controllers/application_controller.rb")
          parse_models unless @models_parsed
          process_controller(source_map, ns)
        else
          []
        end
      end

      private

      def parse_models
        Dir.glob("app/models/**/*.rb").each do |filename|
          source     = Solargraph::Source.load_string(File.read(filename), filename)
          node       = Walker.normalize_ast(source)
          class_name = node.children.first.children.last

          process_model(source, Solargraph::Pin::Namespace.new(name: class_name.to_s))
        end
      end

      def process_model(source, ns)
        walker = Walker.from_source(source)
        pins   = []

        walker.on :send, [nil, :devise] do |ast|
          @seen_devise_models << ns

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
        Solargraph.logger.debug("[ARC][Devise] added #{pins.map(&:name)} to #{ns.path}") if pins.any?
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

        mapping_pins = @seen_devise_models.map do |ns|
          ast = Walker.normalize_ast(source_map.source)
          mapping = ns.name.underscore

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
              types: [ns.name, "nil"],
              location: Util.build_location(ast, ns.filename)
            ),
            Util.build_public_method(
              ns,
              "#{mapping}_session",
              location: Util.build_location(ast, ns.filename)
            )
          ]
        end.flatten

        pins += mapping_pins
        Solargraph.logger.debug("[ARC][Devise] added #{pins.map(&:name)} to #{ns.path}") if pins.any?
        pins
      end
    end
  end
end
