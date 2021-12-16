module Solargraph
  module Arc
    class RailsApi
      def self.instance
        @instance ||= self.new
      end

      def global yard_map
        return [] if yard_map.required.empty?

        ann    = File.read(File.dirname(__FILE__) + "/annotations.rb")
        source = Solargraph::Source.load_string(ann, "annotations.rb")
        map    = Solargraph::SourceMap.map(source)

        Solargraph.logger.debug("[Rails] found #{map.pins.size} pins in annotations")

        overrides = YAML.load_file(File.dirname(__FILE__) + "/types.yml").map do |meth, types|
          Util.method_return(meth, types)
        end

        ns = Solargraph::Pin::Namespace.new(
          name:  "ActionController::Base",
          gates: ["ActionController::Base"]
        )

        definitions = [
          Util.build_public_method(
            ns,
            "response",
            types: ["ActionDispatch::Response"],
            location: Util.dummy_location("whatever.rb")
          ),
          Util.build_public_method(
            ns,
            "request",
            types: ["ActionDispatch::Request"],
            location: Util.dummy_location("whatever.rb")
          ),
          Util.build_public_method(
            ns,
            "session",
            types: ["ActionDispatch::Request::Session"],
            location: Util.dummy_location("whatever.rb")
          ),
          Util.build_public_method(
            ns,
            "flash",
            types: ["ActionDispatch::Flash::FlashHash"],
            location: Util.dummy_location("whatever.rb")
          ),
          Solargraph::Pin::Reference::Override.from_comment(
            "ActionDispatch::Routing::RouteSet#draw",
            "@yieldself [ActionDispatch::Routing::Mapper]"
          )
        ]

        map.pins + definitions + overrides
      end

      def local(source_map, ns)
        return [] unless source_map.filename.include?("db/migrate")
        node = Walker.normalize_ast(source_map.source)

        [
          Util.build_module_include(
            ns,
            "ActiveRecord::ConnectionAdapters::SchemaStatements",
            Util.build_location(node, ns.filename)
          ),
          Util.build_module_extend(
            ns,
            "ActiveRecord::ConnectionAdapters::SchemaStatements",
            Util.build_location(node, ns.filename)
          )
        ]
      end
    end
  end
end
