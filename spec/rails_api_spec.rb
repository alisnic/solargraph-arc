require 'spec_helper'

RSpec.describe SolarRails::RailsApi do
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

  xit "can auto-complete inside routes" do
    Solargraph.logger.level = Logger::DEBUG

    map = use_workspace "./spec/rails5" do |root|
      root.write_file 'config/routes.rb', <<~EOS
        Rails.application.routes.draw do
          res
        end
      EOS
    end

    filename = './config/routes.rb'
    expect(completion_at(filename, [1, 5], map)).to include("resource")
  end

  it "can auto-complete inside migrations" do
    map = use_workspace "./spec/rails5" do |root|
      root.write_file 'db/migrate/20130502114652_create_things.rb', <<~EOS
        class CreateThings < ActiveRecord::Migration[5.2]
          def self.up
            crea
          end

          def change
            crea
          end
        end
      EOS
    end

    filename = './db/migrate/20130502114652_create_things.rb'
    expect(completion_at(filename, [2, 7], map)).to include("create_table")
    expect(completion_at(filename, [6, 7], map)).to include("create_table")
  end

  it "provides completions for ActiveRecord::Base" do
    map = use_workspace "./spec/rails5"

    assert_matches_definitions(
      map,
      "ActiveRecord::Base",
      :activerecord5,
      print_stats: true
    )
  end

  it "provides completions for ActionController::Base" do
    map = use_workspace "./spec/rails5"
    assert_matches_definitions(
      map,
      "ActionController::Base",
      :actioncontroller5,
      print_stats: true
    )
  end
end
