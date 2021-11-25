require 'solargraph'
require 'pry'

Solargraph.logger.level = Logger::DEBUG

class Repl
  attr_reader :api_map
  def initialize
    @api_map = Solargraph::ApiMap.load('./')
  end

  def autocomplete(query, position=nil)
    position ||= [0, query.size]

    source = Solargraph::Source.load_string(query, 'repl.rb')
    map = Solargraph::SourceMap.map(source)
    sources = @api_map.source_maps
    sources.delete_if {|s| s.filename == "repl.rb" }
    sources << map

    bench = Solargraph::Bench.new(source_maps: sources)
    @api_map.catalog bench

    clip = @api_map.clip_at('repl.rb', position)
    cursor = clip.send(:cursor)
    word = cursor.chain.links.first.word

    Solargraph.logger.debug("Complete: word=#{word}, links=#{cursor.chain.links}")

    clip.complete.pins.map(&:name)
  end

  def run
    pry
  end
end

Repl.new.run
