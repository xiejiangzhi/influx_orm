module InfluxORM
  class Query
    attr_reader :model

    def initialize(model)
      @model = model

      @select = "*"
      @conds = {}
      @group = nil
      @limit = nil

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
      @conds = conds
      self
    end

    def group_by(group)
      @group = group
      self
    end

    def order_by(order)
    end

    def limit(n)
      @limit = n
      self
    end

    def slimit(n)
    end

    def offset(n)
    end

    def soffset(n)
    end

    def to_sql
      sql = "SELECT #{@select} FROM #{model.table_name}"
      sql += " WHERE #{conds_to_s}" unless @conds.empty?
      sql += " GROUP BY #{@group}" if @group
      sql += " LIMIT #{@limit}" if @limit
      sql
    end

    def result
      @result ||= begin
        sql = to_sql
        Rails.logger.debug("[InfluxDB] #{sql}")
        model.db.query(sql)
      end
    end

    private

    def conds_to_s
      return @conds if @conds.is_a?(String)
      @conds.map { |k, v| "#{k} = '#{v}'" }.join(' AND ')
    end
  end
end

