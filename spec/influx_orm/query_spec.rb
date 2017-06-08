module InfluxORM
  RSpec.describe Query do
    let(:conn) { Connection.new(database: 'test') }
    let(:query) { model.query }
    let(:model) do
      c = conn
      Class.new do
        def self.table_name
          'tt'
        end

        def self.query
          Query.new(self)
        end

        def self.logger
          Logger.new('/dev/null')
        end

        define_singleton_method(:connection) { @connection ||= c }
      end
    end

    before :each do
      conn.db.delete_database
      conn.db.create_database
    end

    describe '#select' do
      it 'should set select args' do
        expect(query.select('value').to_sql).to eql('SELECT value FROM tt')
        expect(query.select('other').to_sql).to eql('SELECT other FROM tt')
      end

      it 'should set select args with hash' do
        expect(query.select(mean: '*').to_sql).to eql('SELECT mean(*) FROM tt')
        expect(query.select(mean: 'a', max: :b).to_sql).to eql('SELECT mean(a), max(b) FROM tt')
      end
    end

    describe '#where' do
      it 'should save condition' do
        expect(query).to receive(:format_conds).with([{t: 'a'}], :and).and_return('cond_str')

        expect(query.where(t: 'a').to_sql).to eql("SELECT * FROM tt WHERE cond_str")
      end

      it 'should save multiple where condition' do
        expect(query).to receive(:format_conds).with(
          [{t: 'a'}, 'str_cond', {o: 1}], :and
        ).and_return('cond_str2')

        expect(query.where(t: 'a').where('str_cond').where(o: 1).to_sql).to \
          eql("SELECT * FROM tt WHERE cond_str2")
      end
    end

    describe '#or' do
      it 'should save condition' do
        expect(query).to receive(:format_conds).with([{t: 'a'}], :or).and_return('cond_str')

        expect(query.or(t: 'a').to_sql).to eql("SELECT * FROM tt WHERE cond_str")
      end

      it 'should save multiple where condition' do
        expect(query).to receive(:format_conds).with(
          [{t: 'a'}, 'str_cond', {o: 1}], :or
        ).and_return('cond_str2')

        expect(query.or(t: 'a').or('str_cond').or(o: 1).to_sql).to \
          eql("SELECT * FROM tt WHERE cond_str2")
      end

      it 'should save conds if mix where query' do
        expect(query).to receive(:format_conds).with([{t: 'a'}], :and).and_return('cond_str1')
        expect(query).to receive(:format_conds).with([{t: 'b'}], :or).and_return('cond_str2')

        expect(query.where(t: 'a').or(t: 'b').to_sql).to \
          eql("SELECT * FROM tt WHERE cond_str1 OR cond_str2")
      end
    end

    describe '#group_by' do
      it 'should support group_by query' do
        expect(query.select(mean: '*').group_by("time(10s)").to_sql).to eql(
          "SELECT mean(*) FROM tt GROUP BY time(10s)"
        )
        expect(query.select(mean: '*').group_by("time(10s)", :tag).to_sql).to eql(
          "SELECT mean(*) FROM tt GROUP BY time(10s), tag"
        )
      end

      it 'should support mix query' do
        query.select("count(v)").where(t: 'a', t2: 1).group_by('host')
        expect(query.to_sql).to eql(
          "SELECT count(v) FROM tt WHERE (t = 'a' AND t2 = 1) GROUP BY host"
        )
      end
    end

    describe '#fill' do
      it 'should support fill query' do
        expect(query.select(mean: '*').group_by("time(10s)").fill(0).to_sql).to eql(
          "SELECT mean(*) FROM tt GROUP BY time(10s) fill(0)"
        )
      end
    end

    describe '#order_by' do
      it 'should support order_by hash' do
        expect(query.order_by(time: :desc).to_sql).to eql("SELECT * FROM tt ORDER BY time desc")
      end

      it 'should support order_by string' do
        expect(query.order_by('time ASC').to_sql).to eql("SELECT * FROM tt ORDER BY time ASC")
      end
    end

    describe '#limit' do
      it 'should support limit' do
        expect(query.limit(10).to_sql).to eql("SELECT * FROM tt LIMIT 10")
      end
    end

    describe '#slimit' do
      it 'should support slimit' do
        expect(query.slimit(5).to_sql).to eql("SELECT * FROM tt SLIMIT 5")
      end
    end

    describe '#offset' do
      it 'should support offset' do
        expect(query.offset(3).to_sql).to eql("SELECT * FROM tt OFFSET 3")
      end
    end

    describe '#soffset' do
      it 'should support soffset' do
        expect(query.offset(9).to_sql).to eql("SELECT * FROM tt OFFSET 9")
      end
    end

    describe '#to_sql' do
      it 'mix query should return sql' do
        sql = query.select(mean: '*').where(a: 1, time: {gt: 'now() - 1d'}).or(c: 3) \
          .group_by('time(10m)', 'tag').limit(5).slimit(3).offset(1).soffset(1).to_sql
        expect(sql).to eql(
          'SELECT mean(*) FROM tt WHERE (a = 1 AND time > now() - 1d)' \
          ' OR (c = 3) GROUP BY time(10m), tag LIMIT 5 SLIMIT 3 OFFSET 1 SOFFSET 1'
        )
      end
    end

    describe '#result' do
      it 'should query via mode.connection' do
        expect(model.connection).to receive(:query).with('query_str').and_return('result_xx')
        allow(query).to receive(:to_sql).and_return('query_str')

        expect(query.result).to eql('result_xx')
      end

      it 'should cache result' do
        expect(model.connection).to \
          receive(:query).with('query_str').and_return('result_xx').once.times
        allow(query).to receive(:to_sql).and_return('query_str')

        expect(query.result).to eql('result_xx')
        expect(query.result).to eql('result_xx')
      end
    end

    describe 'reload' do
      it 'should re-query result' do
        allow(model.connection).to receive(:query).and_return('result_11')
        expect(query.result).to eql('result_11')
        expect(query.result).to eql('result_11')

        expect(model.connection).to receive(:query).and_return('result_22')
        expect(query.reload).to eql('result_22')
        expect(query.result).to eql('result_22')
      end
    end

    describe 'format_conds' do
      it 'should convert conds to string if relation is :and' do
        expect(query.format_conds([
          {a: 1, b: '2'}, 'c = 12', {d: 2, e: true}, {f: 1}
        ], :and)).to eql(
          "(a = 1 AND b = '2') AND (c = 12) AND (d = 2 AND e = true) AND (f = 1)"
        )
      end

      it 'should convert conds to string if relation is :or' do
        expect(query.format_conds([
          {a: 1, b: '2'}, 'c = 12', {d: 2, e: true}, {f: 1}
        ], :or)).to eql(
          "(a = 1 AND b = '2') OR (c = 12) OR (d = 2 AND e = true) OR (f = 1)"
        )
      end

      it 'should support comparison operation' do
        expect(query.format_conds([
          {a: {gt: 1, lte: 5}, b: {gte: 4}, c: 1}, {time: {gte: 'now() - 1d'}}
        ], :and)).to eql(
          "(a > 1 AND a <= 5 AND b >= 4 AND c = 1) AND (time >= now() - 1d)"
        )
      end
    end
  end
end

