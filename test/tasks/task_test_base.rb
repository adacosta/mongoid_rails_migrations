require_relative '../helper'

load 'lib/mongoid_rails_migrations/mongoid_ext/railties/database.rake'

module Mongoid
  class TaskTestBase < Minitest::Test #:nodoc:
    def setup
      invoke("db:mongoid:drop")
      with_env("MONGOID_CLIENT_NAME" => "shard1") do
        invoke("db:mongoid:drop")
      end
    end

    def teardown
      Mongoid::Migrator.migrations_path = ["db/migrate"]
    end
  end
end
