module SolarRails
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

      if pins.any?
        Solargraph.logger.debug("[Rails][Relation] seeded #{pins.size} methods for #{ns.path}")
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
        types: ["ActiveRecord::Associations::CollectionProxy<#{relation_name.to_s.singularize.camelize}>"],
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
        types: [relation_name.to_s.camelize],
        ast:   ast,
        path:  ns.filename
      )
    end
  end
end
