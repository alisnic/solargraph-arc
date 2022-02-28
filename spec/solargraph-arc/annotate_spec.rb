require 'spec_helper'

RSpec.describe Solargraph::Arc::Annotate do
  let(:api_map) { Solargraph::ApiMap.new }

  it 'auto completes implicit nested classes' do
    load_string 'test1.rb',
                <<~RUBY
      #  id                        :integer          not null, primary key
      #  start_date                :date
      #  living_expenses           :decimal(, )
      #  less_deposits             :boolean          default(FALSE)
      #  notes                     :text
      #  name                      :string
      #  created_at                :datetime
      #  price                     :float
      class MyModel < ApplicationRecord
      end
    RUBY

    assert_public_instance_method(api_map, "MyModel#id", ["Integer"])
  end
end
