require 'spec_helper'

RSpec.describe "test stuff" do
  let(:api_map) { Solargraph::ApiMap.new }

  before do
    Solargraph::Convention.register SolarRails::Convention
  end

  it "auto completes implicit nested classes" do
    load_string 'test1.rb', %(
      class Foo
        def meth(a, b)
          a + b
        end
      end
    )
  end
end
