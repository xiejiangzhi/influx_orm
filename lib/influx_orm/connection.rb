module InfluxORM
  class Connection
    attr_reader :config, :database, :client_config

    def initialize(options)
      @config = options.with_indifferent_access
    end

    def db
      @db ||= InfluxDB::Client.new(config)
    end

    def query(sql)
      db.query(sql)
    end

    def insert(table_name, point)
      db.write_point(table_name, point)
    end

    def import(data)
      db.write_points(data)
    end
  end
end

