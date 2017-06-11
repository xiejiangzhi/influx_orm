require 'logger'

module InfluxORM
  class Configuration
    attr_reader :options
    attr_accessor :logger

    def initialize(options)
      @options = options.deep_symbolize_keys
    end

    def connection
      @connection ||= Connection.new(@options[:connection])
    end

    def module
      @module ||= InitModuleGenerator.new(self)
    end

    def logger
      @logger ||= Logger.new(STDOUT)
    end


    private

    def new_module
      m = self
      Module.new do
        @configuration = m

        def self.configuration
          @configuration
        end

        def self.included(cls)
          include InfluxORM::ModuleHelper
        end
      end
    end
  end
end
