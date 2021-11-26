require 'solargraph'
require 'active_support/core_ext/string/inflections'

require_relative './solar-rails/util.rb'
require_relative './solar-rails/schema.rb'
require_relative './solar-rails/autoload.rb'
require_relative './solar-rails/relation.rb'
require_relative './solar-rails/walker.rb'

module SolarRails
  class Convention < Solargraph::Convention::Base
    def global yard_map
      ann    = File.read(File.dirname(__FILE__) + "/solar-rails/annotations.rb")
      source = Solargraph::Source.load_string(ann, "annotations.rb")
      map    = Solargraph::SourceMap.map(source)

      Solargraph.logger.debug("[Rails] found #{map.pins.size} pins in annotations")
      Solargraph::Environ.new(pins: map.pins)
    end

    def local source_map
      pins = []
      ds   = source_map.document_symbols.select {|n| n.is_a?(Solargraph::Pin::Namespace) }
      ns   = ds.first

      pins += Schema.instance.process(source_map, ns)
      pins += Relation.instance.process(source_map, ns)
      pins += Autoload.instance.process(source_map, ns, ds)

      Solargraph::Environ.new(pins: pins)
    end
  end
end

Solargraph::Convention.register(SolarRails::Convention) unless ENV["RAILS_ENV"] == "test"
