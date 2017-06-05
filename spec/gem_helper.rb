require "bundler/setup"

require 'pry'

require 'spec_helper'

require 'influx_orm'


db_name = 'test'
client = InfluxDB::Client.new

RSpec.configure do |config|
  config.before :all do
    client.create_database db_name
  end

  config.before :each do
    client.delete_database db_name
    client.create_database db_name
  end
end

