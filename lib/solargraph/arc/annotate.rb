module Solargraph
  module Arc
    class Annotate
      def self.instance
        @instance ||= self.new
      end

      def self.reset
        @instance = nil
      end

      def initialize
        @schema_present = File.exist?('db/schema.rb')
      end

      def process(source_map, ns)
        return [] if @schema_present
        []
      end
    end
  end
end
