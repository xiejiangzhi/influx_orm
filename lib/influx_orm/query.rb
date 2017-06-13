module InfluxORM
  class Query
    attr_reader :model

    def initialize(model)
      @model = model

      @select = "*"
      @where_conds = []
      @or_conds = []
      @group = []
      @fill = nil
      @order = nil
      @limit = nil
      @slimit = nil
      @offset = nil
      @soffset = nil

      @result = nil
    end

    def count
      r = select("count(*)").result
      return 0 if r.empty?
      row = r.first['values'].first
      row[row.except('time').keys.first]
    end

    def select(s)
      @select = s
      self
    end

    def where(conds = {})
      @where_conds << conds if conds.present?
      self
    end

    def or(conds = {})
      @or_conds << conds if conds.present?
      self
    end

    def group_by(*group)
      @group = group
      self
    end

    def fill(val)
      @fill = val
      self
    end

    def order_by(order)
      @order = order
      self
    end

    def limit(n)
      @limit = n
      self
    end

    def slimit(n)
      @slimit = n
      self
    end

    def offset(n)
      @offset = n
      self
    end

    def soffset(n)
      @soffset = n
      self
    end

    def to_sql
      sql = "SELECT #{select_to_s} FROM #{model.table_name}"
      if @where_conds.present?
        sql += " WHERE #{format_conds(@where_conds, :and)}"
        sql += " OR #{format_conds(@or_conds, :or)}" if @or_conds.present?
      elsif @or_conds.present?
        sql += " WHERE #{format_conds(@or_conds, :or)}"
      end
      sql += " GROUP BY #{@group.join(', ')}" if @group.present?
      sql += " fill(#{@fill})" if @fill
      sql += " ORDER BY #{order_to_s}" if @order
      sql += " LIMIT #{@limit}" if @limit
      sql += " SLIMIT #{@slimit}" if @slimit
      sql += " OFFSET #{@offset}" if @offset
      sql += " SOFFSET #{@soffset}" if @soffset
      sql
    end

    def result
      @result ||= model.connection.query(to_sql)
    end

    def reload
      @result = nil
      result
    end

    # conds: [{col_name: 'val'}, 'col_name = 1 AND c2 = 2']
    # relation: :and :or
    #
    def format_conds(conds, relation)
      conds_strs = conds.map do |sub_cond|
        next sub_cond if sub_cond.is_a?(String)

        sub_cond.map do |k, v|
          if v.is_a?(Hash)
            compare_cond_to_sql(k, v)
          else
            case v
            when Numeric, true, false then "#{k} = #{v}"
            else "#{k} = '#{v}'"
            end
          end
        end.join(' AND ')
      end

      relation_str = case relation.to_sym
      when :and then ' AND '
      when :or then ' OR '
      else
        raise InfluxORM::Error.new("Invalid relation value '#{relation}'")
      end

      conds_strs.map {|str| "(#{str})" }.join(relation_str)
    end



    private

    def select_to_s
      return @select if @select.is_a?(String)
      @select.map { |k, v| "#{k}(#{v})" }.join(', ')
    end

    def compare_cond_to_sql(name, hash)
      hash.map do |k, v|
        v = format_query_val(v) if name.to_sym == :time

        case k.to_sym
        when :gt then "#{name} > #{v}"
        when :gte then "#{name} >= #{v}"
        when :lt then "#{name} < #{v}"
        when :lte then "#{name} <= #{v}"
        else
          raise "Invalid compare '#{k}'"
        end
      end.join(' AND ')
    end

    def order_to_s
      return @order if @order.is_a?(String)
      @order.map do |k, v|
        "#{k} #{v}"
      end.join(', ')
    end

    def format_query_val(val)
      case val
      when Time, DateTime
        "'#{val.iso8601}'"
      when Date
        "'#{val.to_time.iso8601}'"
      else
        val
      end
    end
  end
end

