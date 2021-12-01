require 'spec_helper'

RSpec.describe SolarRails::Devise do
  let(:api_map) { Solargraph::ApiMap.new }

  before do
    allow(File).to receive(:read).and_call_original
    allow(File).to receive(:read).with("db/schema.rb").and_return("")
    Solargraph::Convention.register SolarRails::Convention
  end

  it "includes devise modules" do
    map = use_workspace "./spec/rails5" do |root|
      root.write_file 'app/models/awesome_user.rb', <<~RUBY
        class AwesomeUser < ActiveRecord::Base
          devise :registerable, :confirmable, :timeoutable, timeout_in: 12.hours
        end
      RUBY

      root.write_file 'app/controllers/pages_controller.rb', <<~RUBY
        class PagesController < ApplicationController
          def index
            curr
            sign
            AwesomeUser.new.conf
          end
        end
      RUBY
    end

    filename = './app/controllers/pages_controller.rb'
    expect(completion_at(filename, [3, 7], map)).to include("sign_in_and_redirect")
    expect(completion_at(filename, [2, 7], map)).to include("current_awesome_user")
    expect(completion_at(filename, [4, 23], map)).to include("confirm")
  end
end
