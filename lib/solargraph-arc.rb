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
require_relative 'solargraph/arc/debug.rb'
require_relative 'solargraph/arc/version.rb'

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
      rescue => error
        Solargraph.logger.warn(error.message + "\n" + error.backtrace.join("\n"))
        EMPTY_ENVIRON
      end

      def local source_map
        pins = []
        ds   = source_map.document_symbols.select {|n| n.is_a?(Solargraph::Pin::Namespace) }
        ns   = ds.first

        return EMPTY_ENVIRON unless ns

        pins += run_feature { Schema.instance.process(source_map, ns) }
        pins += run_feature { Relation.instance.process(source_map, ns) }
        pins += run_feature { Storage.instance.process(source_map, ns) }
        pins += run_feature { Autoload.instance.process(source_map, ns, ds) }
        pins += run_feature { Devise.instance.process(source_map, ns) }
        pins += run_feature { Delegate.instance.process(source_map, ns) }
        pins += run_feature { RailsApi.instance.local(source_map, ns) }

        Solargraph::Environ.new(pins: pins)
      end

      private

      def run_feature(&block)
        yield
      rescue => error
        Solargraph.logger.warn(error.message + "\n" + error.backtrace.join("\n"))
        []
      end
    end
  end
end

Solargraph::Convention.register(Solargraph::Arc::Convention) unless ENV["RAILS_ENV"] == "test"
