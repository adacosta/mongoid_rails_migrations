require File.dirname(__FILE__) + '/../lib/mongoid_rails_migrations'

Mongoid.configure do |config|
  name = "mongoid_test"
  host = "localhost"
  config.master = Mongo::Connection.new.db(name)
end

# require all models
Dir[File.dirname(__FILE__) + "/models/*.rb"].each {|file| require file }

MIGRATIONS_ROOT = File.dirname(__FILE__) + '/migrations'