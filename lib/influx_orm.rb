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

  autoload :Error

  def self.included(cls)
    # cls.extend(ClassMethods)
  end
end

InfluxOrm = InfluxORM

