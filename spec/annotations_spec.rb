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
          pro
          def index
            re
            par
            coo
            ses
            fla
          end
        end
      EOS
    end

    expect(completion_at('./app/controllers/things_controller.rb', [1, 4], map)).to include("protect_from_forgery")

    expect(completion_at('./app/controllers/things_controller.rb', [3, 5], map)).to include("respond_to", "redirect_to", "response", "request")

    expect(completion_at('./app/controllers/things_controller.rb', [4, 6], map)).to include("params")
    expect(find_pin("ActionController::Metal#params", map).return_type.tag).to eq("ActionController::Parameters")

    expect(completion_at('./app/controllers/things_controller.rb', [5, 6], map)).to include("cookies")
    expect(find_pin("ActionController::Cookies#cookies", map).return_type.tag).to eq("ActionDispatch::Cookies::CookieJar")


    expect(completion_at('./app/controllers/things_controller.rb', [6, 6], map)).to include("session")
    expect(completion_at('./app/controllers/things_controller.rb', [7, 6], map)).to include("flash")

    expect(completion_at('./app/models/model.rb', [6, 9], map)).to include("find")
  end
end
