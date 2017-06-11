module InfluxORM::Attributes
  ATTR_TYPES = %w{int float string boolean}.map(&:to_sym)

  def self.included(cls)
    cls.extend(ClassMethods)
  end

  module ClassMethods
    def influx_attrs
      @influx_attrs ||= {}
    end

    def influx_tag(name)
      influx_attrs[name.to_sym] = [:tags, :string]
    end

    def influx_value(name, type = :int)
      raise InfluxORM::Error.new("Invalid type '#{type}'") unless ATTR_TYPES.include?(type)
      influx_attrs[name.to_sym] = [:values, type]
    end

    def attrs_to_point(hash)
      point = {tags: {}, values: {}}

      hash.each do |k, v|
        next if k == :timestamp

        if k.to_sym == :time
          point[:timestamp] = format_timestamp(v)
          next
        end

        col_type, data_type = influx_attrs[k.to_sym]
        raise InfluxORM::Error.new("Invalid col_type '#{col_type}' of '#{k}'") unless col_type
        point[col_type][k] = convert_val(data_type, v)
      end

      point[:timestamp] ||= format_timestamp(Time.now)
      point
    end


    private

    def convert_val(data_type, val)
      case data_type.to_sym
      when :int then val.to_i
      when :float then val.to_f
      when :string then val.to_s
      when :boolean then val ? true : false
      else
        raise InfluxORM::Error.new("Invalid data_type '#{data_type}'")
      end
    end

    def format_timestamp(ts)
      case ts
      when Time, DateTime then ts.to_i
      when Date then ts.to_time.to_i
      when Numeric then ts.to_i
      else
        raise InfluxORM::Error.new("Invalid timestamp value: '#{ts.inspect}'")
      end
    end
  end
end

