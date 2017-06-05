# InfluxORM::Model
#
# dependent InfluxORM::Query
# dependent class method `attrs_to_point` `connection`
#
module InfluxORM::Model
  def self.included(cls)
    cls.extend(ClassMethods)
  end

  module ClassMethods
    def table_name
      @table_name ||= name.gsub('::', '_').tableize
    end

    %w{
      count select where
      group_by fill order_by
      limit slimit offset soffset
    }.each do |mname|
      define_method mname do |*args|
        query.send(mname, *args)
      end
    end

    def insert(point_attrs)
      connection.insert(attrs_to_point(point_attrs))
    end

    # dependent class method: attrs_to_point
    def import(points_attrs)
      points = points_attrs.map do |point_attrs|
        attrs_to_point(point_attrs)
      end
      connection.import(points)
    end


    private

    def query
      InfluxORM::Query.new(self)
    end
  end
end

