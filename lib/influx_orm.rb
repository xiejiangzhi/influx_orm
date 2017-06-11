require "influx_orm/version"

require 'influxdb'

require 'active_support'
require 'active_support/core_ext'

module InfluxORM
  extend ActiveSupport::Autoload

  autoload :Model
  autoload :Query
  autoload :Connection
  autoload :Attributes
  autoload :Configuration
  autoload :InitModuleGenerator

  autoload :Error


  class << self
    attr_reader :configuration

    def setup(options)
      @configuration = Configuration.new(options)
    end

    def included(cls)
      raise Error.new("Please setup with 'InfluxORM.setup' before include") unless configuration
      cls.include(configuration.module)
    end
  end
end

InfluxOrm = InfluxORM

