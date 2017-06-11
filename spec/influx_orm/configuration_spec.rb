module InfluxORM
  RSpec.describe Configuration do
    let(:configuration) do
      Configuration.new(
        connection: {
          database: 'test',
          a: 1
        }
      )
    end

    describe '#connection' do
      it 'should return connection object and cache it' do
        expect(Connection).to receive(:new).with({database: 'test', a: 1}).and_call_original
        expect(configuration.connection).to be_a(Connection)
        expect(configuration.connection).to be_a(Connection)
      end
    end

    describe '#module' do
      it 'should return a ORM module' do
        expect(InitModuleGenerator).to receive(:new).with(configuration).and_return('mmm')
        expect(configuration.module).to eql('mmm')
      end
    end
  end
end

