module SolarRails
  class Devise
    def self.instance
      @instance ||= self.new
    end

    def process(source_map, ns)
      return [] unless source_map.filename.include?("app/models")

      ast    = source_map.source.node
      walker = Walker.new(ast)
      pins   = []

      walker.on :send, [nil, :devise] do |ast|
        modules = ast.children[2..-1]
          .map {|c| c.children.first }
          .select {|s| s.is_a?(Symbol) }

        modules.each do |mod|
          pins << Util.build_module_include(
            ns,
            "Devise::Models::#{mod.to_s.capitalize}",
            ast:  ast,
            path: ns.filename
          )
        end
      end

      walker.walk
      pins
    end
  end
end
