module SolarRails
  class Autoload
    def self.instance
      @instance ||= self.new
    end

    def process(source_map, ns, ds)
      return [] unless ds.size == 1 && ns.path.include?("::")
      Solargraph.logger.debug("[Rails][NamespaceHack] seeding class tree for #{ns.path}")

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
end