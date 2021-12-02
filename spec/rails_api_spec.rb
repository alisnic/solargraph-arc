require 'spec_helper'

RSpec.describe SolarRails::RailsApi do
  let(:api_map) { Solargraph::ApiMap.new }

  before do
    allow(File).to receive(:read).and_call_original
    allow(File).to receive(:read).with("db/schema.rb").and_return("")
    Solargraph::Convention.register SolarRails::Convention
  end

  it "it provides Rails controller api" do
    map = use_workspace "./spec/rails5" do |root|
      root.write_file 'app/controllers/things_controller.rb', <<~EOS
        class ThingsController < ActionController::Base
          def index
            re
            par
            coo
            ses
            fla
          end
        end
      EOS

      root.write_file 'app/controllers/stuff_controller.rb', <<~EOS
        class StuffController < ActionController::Base
          pro
          res
          def index;end
        end
      EOS
    end

    expect(completion_at('./app/controllers/stuff_controller.rb', [1, 4], map)).to include("protect_from_forgery")
    expect(completion_at('./app/controllers/stuff_controller.rb', [2, 4], map)).to include("rescue_from")

    expect(completion_at('./app/controllers/things_controller.rb', [2, 5], map))
      .to include("respond_to", "redirect_to", "response", "request", "render")

    expect(completion_at('./app/controllers/things_controller.rb', [3, 6], map)).to include("params")
    expect(find_pin("ActionController::Metal#params", map).return_type.tag).to eq("ActionController::Parameters")

    expect(completion_at('./app/controllers/things_controller.rb', [4, 6], map)).to include("cookies")
    expect(find_pin("ActionController::Cookies#cookies", map).return_type.tag).to eq("ActionDispatch::Cookies::CookieJar")


    expect(completion_at('./app/controllers/things_controller.rb', [5, 6], map)).to include("session")
    expect(completion_at('./app/controllers/things_controller.rb', [6, 6], map)).to include("flash")
  end

  it "provides completions for ActiveRecord::Base" do
    map = use_workspace "./spec/rails5"
    assert_matches_definitions(map, "ActiveRecord::Base", :activerecord5)
  end

  it "provides Rails Model api" do
    map = use_workspace "./spec/rails5" do |root|
      root.write_file 'app/models/model.rb', <<~EOS
        class ApplicationRecord < ActiveRecord::Base
          self.abstract_class = true
        end

        class Model < ActiveRecord::Base
        end
        Model.find
        Model.whe
        Model.where.not(foo: "bar").whe
        Model.sel
        Model.ord
      EOS
    end

    filename = './app/models/model.rb'

    binding.pry
    # map.get_methods("Model", scope: :class, visibility: [:public])
    expect(completions_for(map, filename, [6, 9]))
      .to include("find" => ["self", "Array<self>"])

    expect(completions_for(map, filename, [7, 8]))
      .to include("where" => ["self", "ActiveRecord::Relation", "ActiveRecord::QueryMethods::WhereChain"])

    # expect(completions_for(map, filename, [8, 30]))
    #   .to include("where" => ["self", "ActiveRecord::Relation", "ActiveRecord::QueryMethods::WhereChain"])

    pp completions_for(map, filename, [9, 9])
    pp completions_for(map, filename, [10, 9])
  end
end
