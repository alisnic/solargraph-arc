require 'spec_helper'

RSpec.describe SolarRails::Delegate do
  let(:api_map) { Solargraph::ApiMap.new }

  before do
    Solargraph::Convention.register SolarRails::Convention
  end

  it "generates methods for singular association" do
    load_string 'app/thing.rb', <<-RUBY
      class Thing
        delegate :one, :two, to: :foo
        def foo
          Foo.new
        end
      end
    RUBY

    assert_public_instance_method(api_map, "Thing#one", "undefined")
    assert_public_instance_method(api_map, "Thing#two", "undefined") do |pin|
      expect(pin.location.range.to_hash).to eq({
        :start => { :line => 1, :character => 0 },
        :end => { :line=>1, :character => 8 }
      })
    end
  end
end
