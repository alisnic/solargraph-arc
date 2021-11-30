require 'solargraph'
require 'active_support/core_ext/string/inflections'

require_relative './solar-rails/util.rb'
require_relative './solar-rails/schema.rb'
require_relative './solar-rails/autoload.rb'
require_relative './solar-rails/relation.rb'
require_relative './solar-rails/devise.rb'
require_relative './solar-rails/walker.rb'

# TODO: remove after https://github.com/castwide/solargraph/pull/509 is merged
class Solargraph::YardMap
  def spec_for_require path
    name = path.split('/').first
    spec = Gem::Specification.find_by_name(name, @gemset[name])

    # Avoid loading the spec again if it's going to be skipped anyway
    #
    return spec if @source_gems.include?(spec.name)
    # Avoid loading the spec again if it's already the correct version
    if @gemset[spec.name] && @gemset[spec.name] != spec.version
      begin
        return Gem::Specification.find_by_name(spec.name, "= #{@gemset[spec.name]}")
      rescue Gem::LoadError
        Solargraph.logger.warn "Unable to load #{spec.name} #{@gemset[spec.name]} specified by workspace, using #{spec.version} instead"
      end
    end
    spec
  end
end

module SolarRails
  class Convention < Solargraph::Convention::Base
    def global yard_map
      ann    = File.read(File.dirname(__FILE__) + "/solar-rails/annotations.rb")
      source = Solargraph::Source.load_string(ann, "annotations.rb")
      map    = Solargraph::SourceMap.map(source)

      Solargraph.logger.debug("[Rails] found #{map.pins.size} pins in annotations")

      overrides = [
        Util.method_return("ActionController::Metal#params", "ActionController::Parameters")
      ]

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
        )
      ]

      Solargraph::Environ.new(pins: map.pins + definitions + overrides)
    end

    #<Solargraph::Pin::Reference::Include ``
    def local source_map
      pins = []
      ds   = source_map.document_symbols.select {|n| n.is_a?(Solargraph::Pin::Namespace) }
      ns   = ds.first

      pins += Schema.instance.process(source_map, ns)
      pins += Relation.instance.process(source_map, ns)
      pins += Autoload.instance.process(source_map, ns, ds)
      pins += Devise.instance.process(source_map, ns)

      Solargraph::Environ.new(pins: pins)
    end
  end
end

Solargraph::Convention.register(SolarRails::Convention) unless ENV["RAILS_ENV"] == "test"
