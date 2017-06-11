module InfluxORM
  RSpec.describe InitModuleGenerator do
    let(:configuration) { double('configuration', connection: 'connection') }

    describe '.new' do
      let(:m) { subject.new(configuration) }

      it 'should return init module and save configuration' do
        expect(m).to be_a(Module)
        expect(m.configuration).to eql(configuration)
      end

      it 'should define :connection :configuration methods when other class included it' do
        a = Class.new
        expect {
          a.include(m)
        }.to change { a.respond_to?(:connection) }.to(true)

        expect(a.connection).to eql(configuration.connection)
      end

      it 'should include Model and Attributes when other class included it' do
        a = Class.new
        a.include(m)

        expect(a.included_modules).to be_include(Model)
        expect(a.included_modules).to be_include(Attributes)
      end
    end
  end
end

