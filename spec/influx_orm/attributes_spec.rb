RSpec.describe InfluxORM::Attributes do
  let(:cls) { Class.new { include InfluxORM::Attributes } }

  describe '#influx_tag' do
    it 'should add tag to influx_attrs' do
      expect {
        cls.influx_tag :a
        cls.influx_tag :b
      }.to change(cls.influx_attrs, :length).by(2)

      expect(cls.influx_attrs).to eql({
        a: [:tags, :string],
        b: [:tags, :string]
      })
    end
  end

  describe '#influx_value' do
    it 'should add value to influx_attrs' do
      expect {
        cls.influx_value :v1
        cls.influx_value :asdf, :float
        cls.influx_value :asdf, :float
      }.to change(cls.influx_attrs, :length).by(2)

      expect(cls.influx_attrs).to eql({
        v1: [:values, :int],
        asdf: [:values, :float]
      })
    end

    it 'should raise error if give invalid type' do
      expect {
        cls.influx_value :v1, :invalid
      }.to raise_error(InfluxORM::Error)
    end
  end

  describe '#attrs_to_point' do
    before :each do
      cls.class_eval do
        influx_tag :ta
        influx_value :va
        influx_value :vb, :float
        influx_value :vc, :boolean
      end
    end

    it 'should convert attrs to point' do
      expect(cls.attrs_to_point(ta: 1, va: '1', vb: 1, vc: 123)).to \
        eql(tags: {ta: '1'}, values: {va: 1, vb: 1.0, vc: true}, timestamp: Time.now.to_i)

      expect(cls.attrs_to_point(ta: '123', va: 2.23, vb: 2.1, vc: false)).to \
        eql(tags: {ta: '123'}, values: {va: 2, vb: 2.1, vc: false}, timestamp: Time.now.to_i)

      expect(cls.attrs_to_point(ta: {}, va: '', vb: '2.1', vc: 'asdf')).to \
        eql(tags: {ta: '{}'}, values: {va: 0, vb: 2.1, vc: true}, timestamp: Time.now.to_i)

      expect(cls.attrs_to_point(ta: {}, va: '', vb: '2.1')).to \
        eql(tags: {ta: '{}'}, values: {va: 0, vb: 2.1}, timestamp: Time.now.to_i)
    end

    it 'should convert time to timestamp' do
      expect(cls.attrs_to_point(ta: {}, va: '', vb: '2.1', vc: 'asdf')).to \
        eql(tags: {ta: '{}'}, values: {va: 0, vb: 2.1, vc: true}, timestamp: Time.now.to_i)
    end
  end
end
