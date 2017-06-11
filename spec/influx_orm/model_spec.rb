RSpec.describe InfluxORM::Model do
  let(:model) { Class.new { include InfluxORM::Model } }

  describe '.table_name' do
    it 'should generate table_name with class name' do
      MyTestModel = Class.new { include InfluxORM::Model }
      expect(MyTestModel.table_name).to eql('my_test_models')

      Testasdfa = Class.new { include InfluxORM::Model }
      expect(Testasdfa.table_name).to eql('testasdfas')
    end
  end

  %w{
    count select where
    group_by fill order_by
    limit slimit offset soffset
  }.each do |query_method|
    describe "\##{query_method}" do
      it "should proxy #{query_method} to query" do
        query = double('query', query_method: true)
        args = rand

        allow(InfluxORM::Query).to receive(:new).with(model).and_return(query)
        expect(query).to receive(query_method).with(args)

        model.send(query_method, args)
      end
    end
  end

  describe '.insert' do
    let(:conn) { double('connection') }

    before :each do
      c = conn
      model.class_eval do
        include InfluxORM::Attributes
        define_singleton_method(:table_name) { 'my_table' }
        define_singleton_method(:connection) { c }
      end
    end

    it 'should format and write point' do
      point = {tags: {t: 't'}, values: {v: 1}}
      expect(model).to receive(:attrs_to_point).with(t: 't', v: 1).and_return(point)
      expect(conn).to receive(:insert).with('my_table', point)

      model.insert(t: 't', v: 1)
    end
  end

  describe '.import' do
    let(:conn) { double('connection') }

    before :each do
      c = conn
      model.class_eval do
        include InfluxORM::Attributes
        define_singleton_method(:connection) { c }
        define_singleton_method(:table_name) { 'asdf' }
      end
    end

    it 'should format and write points' do
      points = [
        {tags: {t: 't'}, values: {v: 1}}, {tags: {t: 't2'}, values: {v: 2}, series: 'ab'}
      ]
      expect(model).to receive(:attrs_to_point).with(t: 't', v: 1).and_return(points[0])
      expect(model).to receive(:attrs_to_point).with(t: 't2', v: 2).and_return(points[1])
      expect(conn).to receive(:import).with(points.each {|p| p[:series] ||= 'asdf' })

      model.import([{t: 't', v: 1}, {t: 't2', v: 2}])
    end
  end
end

