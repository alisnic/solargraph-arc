require 'spec_helper'

RSpec.describe "solargraph rails integration" do
  let(:api_map) { Solargraph::ApiMap.new }

  def assert_public_instance_method(query, return_type, &block)
    pin = find_pin(query)
    expect(pin).to_not be_nil
    expect(pin.scope).to eq(:instance)
    expect(pin.return_type.tag).to eq(return_type)

    yield pin if block_given?
  end

  let(:schema) do
    <<-RUBY
      ActiveRecord::Schema.define(version: 2021_10_20_084658) do

        enable_extension "pg_trgm"

        create_table "accounts", force: :cascade do |t|
          t.jsonb "extra"
          t.decimal "balance", precision: 30, scale: 10, null: false
          t.integer "some_int"
          t.date "some_date"
          t.bigint "some_big_id", null: false
          t.string "name", null: false
          t.boolean "active"
          t.text "notes"
          t.inet "some_ip"
          t.datetime "created_at", null: false
          t.index ["checksum", "login_id"], name: "index_accounts_on_checksum_and_login_id", unique: true
        end
      end
    RUBY
  end

  before do
    allow(File).to receive(:read).and_call_original
    allow(File).to receive(:read).with("db/schema.rb").and_return(schema)
    Solargraph::Convention.register SolarRails
  end

  it "generates method for belongs_to" do
    load_string 'app/models/transaction.rb', <<-RUBY
      class Transaction < ActiveRecord::Base
        belongs_to :account
      end
    RUBY

    assert_public_instance_method("Transaction#account", "Account") do |pin|
      expect(pin.location.range.to_hash).to eq({
        :start => { :line => 1, :character => 0 },
        :end => { :line=>1, :character => 8 }
      })
    end
  end

  it "generates method for has_many" do
    load_string 'app/models/account.rb', <<-RUBY
      class Account < ActiveRecord::Base
        has_many :transactions
      end
    RUBY

    assert_public_instance_method(
      "Account#transactions",
      "ActiveRecord::Associations::CollectionProxy<Transaction>"
    )
  end

  it "generates methods based on schema" do
    load_string 'app/models/account.rb', <<-RUBY
      class Account < ActiveRecord::Base
      end
    RUBY

    assert_public_instance_method("Account#extra", "Hash") do |pin|
      expect(pin.location.range.to_hash).to eq({
        :start => { :line => 5, :character => 0 },
        :end => { :line => 5, :character => 10 }
      })
    end

    assert_public_instance_method("Account#balance", "BigDecimal")
    assert_public_instance_method("Account#some_int", "Integer")
    assert_public_instance_method("Account#some_date", "Date")
    assert_public_instance_method("Account#some_big_id", "Integer")
    assert_public_instance_method("Account#name", "String")
    assert_public_instance_method("Account#active", "Boolean")
    assert_public_instance_method("Account#notes", "String")
    assert_public_instance_method("Account#some_ip", "IPAddr")
  end

  it "auto completes implicit nested classes" do
    load_string 'test1.rb', %(
      class Foo
        class Bar
          class Baz
            def run; end
          end
        end
      end
      Foo::Bar::Baz
    )

    expect(completion_at('test1.rb', [8, 6])).to include("Foo")
    expect(completion_at('test1.rb', [8, 11])).to include("Bar")
    expect(completion_at('test1.rb', [8, 16])).to include("Baz")

    load_string 'test1.rb', %(
      class Foo::Bar::Baz;
        def run; end
      end
      Foo::Bar::Baz
    )

    expect(completion_at('test1.rb', [4, 6])).to include("Foo")
    expect(completion_at('test1.rb', [4, 11])).to include("Bar")
    expect(completion_at('test1.rb', [4, 16])).to include("Baz")
  end
end
