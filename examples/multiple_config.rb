require 'influx_orm'

C1 = InfluxORM.setup(
  connection: {
    database: 'test1'
  }
)
C1.connection.db.delete_database('test1')
C1.connection.db.create_database('test1')
M1 = C1.module

C2 = InfluxORM.setup(
  connection: {
    database: 'test2'
  }
)
C2.connection.db.delete_database('test2')
C2.connection.db.create_database('test2')
M2 = C2.module

class Book
  include M1

  influx_tag :book_id
  influx_tag :category
  influx_value :price, :float
end

class Host
  include M2

  influx_tag :ip
  influx_tag :name
  influx_value :load, :float
end

Book.insert(book_id: 1, category: 'A', price: 1.3)
Host.import([
  {ip: '192.168.1.1', name: 'A', load: 1.3, timestamp: 111},
  {ip: '192.168.1.2', name: 'A', load: 1.5, timestamp: 122},
  {ip: '192.168.1.3', name: 'B', load: 1.5, timestamp: 132},
  {ip: '192.168.1.1', name: 'C', load: 2.5, timestamp: 132}
])

puts '----- Book result --------'
puts Book.select(mean: '*').where(time: {gte: 'now() - 3m'}) \
  .group_by('time(1m)', :category).fill(0).result

puts '----- Host result --------'
puts Host.select(mean: '*').where(time: {gte: 'now() - 30m'}) \
  .group_by('time(10m)', :category).fill(0).result

