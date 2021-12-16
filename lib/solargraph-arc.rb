require 'solargraph'
require 'active_support/core_ext/string/inflections'

require_relative 'solargraph/arc/patches.rb'
require_relative 'solargraph/arc/util.rb'
require_relative 'solargraph/arc/schema.rb'
require_relative 'solargraph/arc/autoload.rb'
require_relative 'solargraph/arc/relation.rb'
require_relative 'solargraph/arc/devise.rb'
require_relative 'solargraph/arc/walker.rb'
require_relative 'solargraph/arc/rails_api.rb'
require_relative 'solargraph/arc/delegate.rb'
require_relative 'solargraph/arc/storage.rb'

module Solargraph
  module Arc
    class NodeParser
      extend Solargraph::Parser::Legacy::ClassMethods
    end

    class Convention < Solargraph::Convention::Base
      def global yard_map
        Solargraph::Environ.new(
          pins: Solargraph::Arc::RailsApi.instance.global(yard_map)
        )
      end

      #<Solargraph::Pin::Reference::Include ``
      def local source_map
        pins = []
        ds   = source_map.document_symbols.select {|n| n.is_a?(Solargraph::Pin::Namespace) }
        ns   = ds.first

        return EMPTY_ENVIRON unless ns

        pins += Schema.instance.process(source_map, ns)
        pins += Relation.instance.process(source_map, ns)
        pins += Storage.instance.process(source_map, ns)
        pins += Autoload.instance.process(source_map, ns, ds)
        pins += Devise.instance.process(source_map, ns)
        pins += Delegate.instance.process(source_map, ns)
        pins += RailsApi.instance.local(source_map, ns)

        Solargraph::Environ.new(pins: pins)
      end
    end
  end
end

Solargraph::Convention.register(Solargraph::Arc::Convention) unless ENV["RAILS_ENV"] == "test"
