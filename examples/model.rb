require 'influx_orm'

InfluxORM.setup(
  connection: {
    database: 'test1'
  }
)
InfluxORM.configuration.connection.db.delete_database('test1')
InfluxORM.configuration.connection.db.create_database('test1')

class Book
  include InfluxORM

  influx_tag :book_id
  influx_tag :category
  influx_value :price, :float
end

Book.insert(book_id: 1, category: 'A', price: 1.3)
Book.import([
  {book_id: 1, category: 'A', price: 1.3, timestamp: 111},
  {book_id: 1, category: 'A', price: 1.5, timestamp: 122},
  {book_id: 2, category: 'B', price: 1.5, timestamp: 132},
  {book_id: 3, category: 'C', price: 2.5, timestamp: 132}
])

puts Book.select(mean: '*').where(time: {gte: 'now() - 3d'}) \
  .group_by('time(12h)', :category).fill(0).result

puts Book.where(category: 'A').where(time: {gte: 'now() - 1d'}).result
puts Book.where(category: 'A').or(category: 'B').result

