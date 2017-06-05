module InfluxORM
  RSpec.describe Query do
    before :each do
      InfluxDB::Rails.client.delete_database
      InfluxDB::Rails.client.create_database
    end

    describe '#table_name' do
      it 'should generate table_name with class name' do
        expect(TS::Base.table_name).to eql('ts_bases')
        expect(TS::Video.table_name).to eql('ts_videos')
      end
    end

    describe '#insert' do
      it 'should insert data to db' do
        expect {
          TS::Video.insert({tags: {a: 1}, values: {v: 2}})
          TS::Video.insert({tags: {a: 2}, values: {v: 2}})
        }.to change(TS::Video, :count).by(2)
      end
    end

    describe '#import' do
      it 'should insert data to db' do
        expect {
          TS::Video.import([
            {tags: {a: 1}, values: {v: 2}},
            {tags: {a: 2}, values: {v: 3}},
            {tags: {a: 3}, values: {v: 2}}
          ])
        }.to change(TS::Video, :count).by(3)
      end
    end

    describe '#to_sql' do
      let(:query) { TS::Query.new(TS::Video) }

      it 'should support select query' do
        expect(query.select('value').to_sql).to eql('SELECT value FROM ts_videos')
        expect(query.select('count(*)').to_sql).to eql('SELECT count(*) FROM ts_videos')
      end

      it 'should support where query' do
        expect(query.where(t: 'a').to_sql).to eql(
          "SELECT * FROM ts_videos WHERE t = 'a'"
        )
        expect(query.where(t: 'a', t2: 1).to_sql).to eql(
          "SELECT * FROM ts_videos WHERE t = 'a' AND t2 = '1'"
        )
        expect(query.where(t: :a).to_sql).to eql(
          "SELECT * FROM ts_videos WHERE t = 'a'"
        )
        expect(query.where("time > now() - 1d").to_sql).to eql(
          "SELECT * FROM ts_videos WHERE time > now() - 1d"
        )
      end

      it 'should support group_by query' do
        expect(query.group_by("time(10s)").to_sql).to eql(
          "SELECT * FROM ts_videos GROUP BY time(10s)"
        )
      end

      it 'should support mix query' do
        query.select("count(v)").where(t: 'a', t2: 1).group_by('time(10s)')
        expect(query.to_sql).to eql(
          "SELECT count(v) FROM ts_videos WHERE t = 'a' AND t2 = '1' GROUP BY time(10s)"
        )
      end
    end

    describe '#result' do
      before :each do
        TS::Video.import([
          {tags: {a: 1, b: 'ab'}, values: {v: 1}},
          {tags: {a: 2, b: 'ab'}, values: {v: 2}},
          {tags: {a: 3, b: 'ac'}, values: {v: 3}},
          {tags: {a: 3, b: 'ad'}, values: {v: 4}}
        ])
      end

      it 'should return result' do
        result = TS::Video.select(:v).where(a: 1).result.first['values']
        expect(result.map {|r| r['v'] }).to eql([1])

        result = TS::Video.where("v > 2").group_by(:b).result
        result.map {|vs| vs['values'].map {|v| v.except!('time') } }
        expect(result).to eql([
          {
            "name"=>"ts_videos", "tags"=>{"b"=>"ac"},
            "values"=>[{ "a"=>"3", "v" => 3}]
          },
          {
            "name" => "ts_videos", "tags" => {'b' => 'ad'},
            "values"=>[{"a"=>"3", "v"=>4}]
          }
        ])
      end
    end
  end
end

