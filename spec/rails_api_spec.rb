require 'spec_helper'

RSpec.describe SolarRails::RailsApi do
  let(:api_map) { Solargraph::ApiMap.new }

  before do
    Solargraph::Convention.register SolarRails::Convention
  end

  it "it provides Rails controller api" do
    map = use_workspace "./spec/rails5" do |root|
      root.write_file 'app/controllers/things_controller.rb', <<~EOS
        class ThingsController < ActionController::Base
          res
          def index
            re
          end
        end
      EOS
    end

    filename = './app/controllers/things_controller.rb'
    expect(completion_at(filename, [1, 4], map)).to include("rescue_from")

    expect(completion_at(filename, [3, 5], map))
      .to include("respond_to", "redirect_to", "response", "request", "render")
  end

  it "provides completions for ActiveRecord::Base" do
    map = use_workspace "./spec/rails5"
    assert_matches_definitions(map, "ActiveRecord::Base", :activerecord5, print_stats: true)
  end

  it "provides completions for ActionController::Base" do
    map = use_workspace "./spec/rails5"
    assert_matches_definitions(map, "ActionController::Base", :actioncontroller5, print_stats: true)
  end
end
