RSpec.describe InfluxORM::Connection do
  let(:conn) { InfluxORM::Connection.new(database: 'test') }
  let(:db) { conn.db }
  let(:counter) do
    Proc.new do |table|
      r = conn.query("select count(*) from #{table}")
      r.empty? ? 0 : r[0]['values'][0]['count_v']
    end
  end

  describe '#db' do
    it 'should return influxdb client' do
      expect(InfluxDB::Client).to receive(:new).with(database: 'test').and_call_original
      expect(conn.db).to be_a(InfluxDB::Client)
    end

    it 'should can read/write data' do
      db.write_point('table', tags: {t: 'a'}, values: {v: 1})

      r = db.query('select * from table')
      expect(r.length).to eql(1)

      rows = r[0]['values'].map {|v| v.except('time')}
      expect(rows).to eql([{'t' => 'a', 'v' => 1}])
    end
  end

  describe '#query' do
    it 'should proxy to db.query' do
      sql = 'select * from my_table'
      expect(db).to receive(:query).with(sql)
      conn.query(sql)
    end
  end

  describe '#insert' do
    it 'should insert data to db' do
      expect {
        conn.insert('ta', {tags: {a: 1}, values: {v: 2}})
        conn.insert('ta', {tags: {a: 2}, values: {v: 2}})
      }.to change { counter.call('ta') }.by(2)

      rows = conn.query('select * from ta')[0]['values'].map {|r| r.except('time') }
      expect(rows).to eql([
        {'a' => '1', 'v' => 2},
        {'a' => '2', 'v' => 2}
      ])
    end
  end

  describe '#import' do
    it 'should insert data to db' do
      expect {
        expect {
          conn.import([
            {tags: {a: 1}, values: {v: 2}, series: 'ta'},
            {tags: {a: 2}, values: {v: 3}, series: 'ta'},
            {tags: {a: 3}, values: {v: 2}, series: 'tb'}
          ])
        }.to change { counter.call('tb') }.by(1)
      }.to change{ counter.call('ta') }.by(2)

      rows = conn.query('select * from ta')[0]['values'].map {|r| r.except('time') }
      expect(rows).to eql([
        {'a' => '1', 'v' => 2},
        {'a' => '2', 'v' => 3}
      ])

      rows = conn.query('select * from tb')[0]['values'].map {|r| r.except('time') }
      expect(rows).to eql([{'a' => '3', 'v' => 2}])
    end
  end
end

