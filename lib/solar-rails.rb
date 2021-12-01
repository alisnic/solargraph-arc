require 'solargraph'
require 'active_support/core_ext/string/inflections'

require_relative './solar-rails/patches.rb'
require_relative './solar-rails/util.rb'
require_relative './solar-rails/schema.rb'
require_relative './solar-rails/autoload.rb'
require_relative './solar-rails/relation.rb'
require_relative './solar-rails/devise.rb'
require_relative './solar-rails/walker.rb'
require_relative './solar-rails/rails_api.rb'

module SolarRails
  class Convention < Solargraph::Convention::Base
    def global yard_map
      Solargraph::Environ.new(
        pins: SolarRails::RailsApi.instance.process(yard_map)
      )
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
