require "spec_helper"

RSpec.describe InfluxORM do
  let(:configuration) { double('c', {module: Module.new, connection: 'conn'}) }

  before :each do
    allow(InfluxORM::Configuration).to receive(:new).and_return(configuration)

    InfluxORM.instance_variables.each do |name|
      InfluxORM.remove_instance_variable(name)
    end
  end

  describe '.setup' do
    it 'should setup default configuration' do

      expect {
        InfluxORM.setup(connection: {database: 'test'})
      }.to change(InfluxORM, :configuration).to(configuration)
    end
  end

  describe 'included' do
    let(:cls) { Class.new }

    it 'should include configuration module' do
      InfluxORM.setup(connection: {database: 'test'})

      expect(cls).to receive(:include).with(InfluxORM).and_call_original
      expect(cls).to receive(:include).with(configuration.module).and_call_original

      cls.include(InfluxORM)
    end

    it "should raise error if don't setup" do
      expect {
        cls.include(InfluxORM)
      }.to raise_error(InfluxORM::Error)
    end
  end

  it "alias InfluxOrm" do
    expect(InfluxOrm).to eql(InfluxORM)
  end

  it "has a version number" do
    expect(InfluxORM::VERSION).not_to be nil
  end
end
