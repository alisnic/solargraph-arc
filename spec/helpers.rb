module Helpers
  def load_string(filename, str)
    source = build_source(filename, str)
    # map = Solargraph::SourceMap.map(source)
    # api_map.catalog Solargraph::Bench.new(source_maps: [map])
    api_map.map(source)
    source
  end

  def assert_matches_definitions(map, class_name, defition_name, update: false)
    definitions = YAML.load_file("spec/definitions/#{defition_name}.yml")

    class_methods = map.get_methods(
      class_name,
      scope: :class, visibility: [:public, :protected, :private]
    )

    instance_methods = map.get_methods(
      class_name,
      scope: :instance, visibility: [:public, :protected, :private]
    )

    definitions.each do |meth, data|
      pin = if meth.start_with?(".")
        class_methods.find {|p| p.name == meth[1..-1] }
      elsif meth.start_with?("#")
        instance_methods.find {|p| p.name == meth[1..-1] }
      end

      if pin
        assert_entry_valid(pin, data)
      else
        # expect(pin).to be_present, "expected to find completion for #{meth}"
        # puts "#{meth} was not found in completions"
      end
    end
  end

  def assert_entry_valid(pin, data, update: false)
    effective_type = pin.return_type.map(&:tag)
    specified_type = data["types"]

    expect(effective_type).to(
      eq(specified_type),
      "#{pin.path} return type is wrong. Expected #{specified_type}, got: #{effective_type}"
    )
  end

  def callstack
    caller.reject {|f| f.include?("pry") || f.include?("rspec") }
  end

  class Injector
    attr_reader :files
    def initialize(folder)
      @folder = folder
      @files  = []
    end

    def write_file(path, content)
      File.write(path, content)
      @files << path
    end
  end

  def use_workspace(folder, &block)
    injector = Injector.new(folder)
    map      = nil

    Dir.chdir folder do
      yield injector if block_given?
      map = Solargraph::ApiMap.load("./")
      injector.files.each {|f| File.delete(f) }
    end

    map
  end

  def assert_public_instance_method(query, return_type, &block)
    pin = find_pin(query)
    expect(pin).to_not be_nil
    expect(pin.scope).to eq(:instance)
    expect(pin.return_type.tag).to eq(return_type)

    yield pin if block_given?
  end

  def build_source(filename, str)
    Solargraph::Source.load_string(str, filename)
  end

  def find_pin(path, map=api_map)
    find_pins(path, map).first
  end

  def find_pins(path, map=api_map)
    map.pins.select {|p| p.path == path }
  end

  def search_pins(name, map=api_map)
    map.pins.select {|p| p.path && p.path.include?(name) }
  end

  def local_pins(map=api_map)
    map.pins.select {|p| p.filename }
  end

  def methods_for(pin: nil, path: nil)
    pin ||= find_pin(path)
    api_map.get_complex_type_methods(pin.return_type)
  end

  def local_methods_for(pin: nil, path: nil)
    methods_for(pin: pin, path: path).select {|m| m.filename }
  end

  def completion_at(filename, position, map=api_map)
    clip = map.clip_at(filename, position)
    cursor = clip.send(:cursor)
    word = cursor.chain.links.first.word

    Solargraph.logger.debug("Complete: word=#{word}, links=#{cursor.chain.links}")

    clip.complete.pins.map(&:name)
  end

  def completions_for(map, filename, position)
    clip = map.clip_at(filename, position)

    clip.complete.pins.map do |pin|
      [pin.name, pin.return_type.map(&:tag)]
    end.to_h
  end
end
