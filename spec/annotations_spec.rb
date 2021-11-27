require 'spec_helper'

RSpec.describe "bundled annotations" do
  let(:api_map) { Solargraph::ApiMap.new }

  before do
    allow(File).to receive(:read).and_call_original
    allow(File).to receive(:read).with("db/schema.rb").and_return("")
    Solargraph::Convention.register SolarRails::Convention
  end

  it "includes activerecord annotations" do
    map = use_workspace "./spec/rails5" do |root|
      root.write_file 'app/models/model.rb', <<~EOS
        class ApplicationRecord < ActiveRecord::Base
          self.abstract_class = true
        end

        class Model < ActiveRecord::Base
        end
        Model.find
      EOS

      root.write_file 'app/controllers/things_controller.rb', <<~EOS
        class ThingsController < ActionController::Base
          def index
            ren
          end
        end
      EOS
    end

    expect(completion_at('./app/models/model.rb', [6, 9], map)).to include("find")
    # expect(completion_at('./app/controllers/things_controller.rb', [2, 6], map)).to include("render")
  end
end
