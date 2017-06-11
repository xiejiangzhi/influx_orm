module InfluxORM
  module InitModuleGenerator
    def self.new(configuration)
      Module.new do
        extend ActiveSupport::Concern
        extend ModuleClassMethods

        @configuration = configuration

        included do |cls|
          @configuration = configuration
          extend ORMClassMethods

          include Model
          include Attributes
        end
      end
    end

    module ORMClassMethods
      def configuration
        @configuration
      end

      def connection
        configuration.connection
      end
    end

    module ModuleClassMethods
      def configuration
        @configuration
      end
    end
  end
end

