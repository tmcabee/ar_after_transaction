`rm db/test.sqlite3` if File.exists?('db/test.sqlite3')

ActiveRecord::Migration.verbose = false

# Alternate DB
ActiveRecord::Base.establish_connection(
  :adapter => 'sqlite3',
  :database => 'db/test.sqlite3'
)

ActiveRecord::Schema.define(:version => 1) do
  create_table :bars do |t|
    t.string :message
    t.integer :foo_id
    t.timestamps
  end
end

# Main DB
ActiveRecord::Base.establish_connection(
  :adapter  => 'sqlite3',
  :database => ':memory:'
)

ActiveRecord::Schema.define(:version => 1) do
  create_table :users do |t|
    t.string :name
    t.timestamps
  end

  create_table :foos do |t|
    t.string :name
    t.timestamps
  end
end

# for detailed debugging:
#require 'logger'
#ActiveRecord::Base.logger = Logger.new(STDOUT)

class Bar < ActiveRecord::Base
  establish_connection(
    :adapter => 'sqlite3',
    :database => 'db/test.sqlite3'
  )
end

class Foo < ActiveRecord::Base
end

class User < ActiveRecord::Base
end