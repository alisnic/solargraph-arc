module Helpers
  def load_string(filename, str)
    source = build_source(filename, str)
    api_map.map(source)
    source
  end

  def build_source(filename, str)
    Solargraph::Source.load_string(str, filename)
  end

  def find_pin(path)
    api_map.pins.find {|p| p.is_a?(Solargraph::Pin::Method) && p.path == path }
  end

  def local_pins
    api_map.pins.select {|p| p.filename }
  end

  def catalog_bench(sources)
    maps = sources.map {|s| Solargraph::SourceMap.map(s) }
    api_map.catalog Solargraph::Bench.new(source_maps: maps)
  end

  def completion_at(filename, position)
    clip = api_map.clip_at(filename, position)
    cursor = clip.send(:cursor)
    word = cursor.chain.links.first.word

    Solargraph.logger.debug("Complete: word=#{word}, links=#{cursor.chain.links}")

    clip.complete.pins.map(&:name)
  end

  def local_pins_hash
    api_map.pins.select {|p| p.filename }.map do |p|
      {
        name:       p.name,
        type:       p.type,
        closure:    p.closure&.path,
        visibility: p.visibility,
        gates:      p.gates
      }
    end
  end
end
