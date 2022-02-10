require 'spec_helper'

RSpec.describe Solargraph::Arc::Devise do
  let(:api_map) { Solargraph::ApiMap.new }

  it "includes devise modules in rails5" do
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
            AwesomeUser.new.conf
          end
        end
      RUBY
    end

    filename = './app/controllers/pages_controller.rb'
    expect(completion_at(filename, [2, 7], map)).to include("current_awesome_user")
    expect(completion_at(filename, [3, 23], map)).to include("confirm")

    assert_public_instance_method(map, "ApplicationController#authenticate_awesome_user!", ['undefined'])
    assert_public_instance_method(map, "ApplicationController#awesome_user_signed_in?", ['true', 'false'])
    assert_public_instance_method(map, "ApplicationController#current_awesome_user", ['AwesomeUser', 'nil'])
    assert_public_instance_method(map, "ApplicationController#awesome_user_session", ['undefined'])
  end

  it "includes devise modules in rails6" do
    map = use_workspace "./spec/rails6" do |root|
      root.write_file 'app/models/awesome_user.rb', <<~RUBY
        class AwesomeUser < ActiveRecord::Base
          devise :registerable, :confirmable, :timeoutable, timeout_in: 12.hours
        end
      RUBY

      root.write_file 'app/controllers/pages_controller.rb', <<~RUBY
        class PagesController < ApplicationController
          def index
            curr
            AwesomeUser.new.conf
          end
        end
      RUBY
    end

    filename = './app/controllers/pages_controller.rb'
    expect(completion_at(filename, [2, 7], map)).to include("current_awesome_user")
    expect(completion_at(filename, [3, 23], map)).to include("confirm")

    assert_public_instance_method(map, "ApplicationController#authenticate_awesome_user!", ['undefined'])
    assert_public_instance_method(map, "ApplicationController#awesome_user_signed_in?", ['true', 'false'])
    assert_public_instance_method(map, "ApplicationController#current_awesome_user", ['AwesomeUser', 'nil'])
    assert_public_instance_method(map, "ApplicationController#awesome_user_session", ['undefined'])
  end
end







