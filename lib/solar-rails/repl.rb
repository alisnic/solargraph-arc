require 'solargraph'
require 'pry'

Solargraph.logger.level = Logger::DEBUG

class Repl
  attr_reader :api_map, :yard_map
  def initialize
    @api_map = Solargraph::ApiMap.load('./')
    @yard_map = @api_map.yard_map
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
    chain  = cursor.chain
    word = cursor.chain.links.first.word

    Solargraph.logger.debug("Complete: word=#{word}, links=#{cursor.chain.links}")
    Solargraph.logger.debug("Complete: chain.constant?=#{chain.constant?}, cursor.start_of_constant?=#{cursor.start_of_constant?}")

    type = cursor.chain.base.infer(api_map, clip.send(:block), clip.locals)
    links_length = chain.links.length
    Solargraph.logger.debug("Complete: type=#{type} chain.links.length=#{links_length}")

    clip.complete.pins.map(&:name)
  end

  def required_gems
    yard_map.required.sort
  end

  def local_pins
    api_pins.select {|p| p.filename}
  end

  def methods_for(pin: nil, path: nil)
    pin ||= find_pin(path)
    api_map.get_complex_type_methods(pin.return_type)
  end

  def local_methods_for(pin: nil, path: nil)
    methods_for(pin: pin, path: path).select {|m| m.filename }
  end

  def find_pin(path)
    api_map.pins.find {|p| p.path == path }
  end

  def run
    pry
  end
end

Repl.new.run
