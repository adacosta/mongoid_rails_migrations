require_relative './task_test_base'

module Mongoid
  class DropTaskTest < TaskTestBase
    def test_drop_database
      Mongoid::Migrator.migrations_path = [MIGRATIONS_ROOT + "/valid"]
      invoke("db:mongoid:migrate")
      assert_output("20100513063902\n") { invoke("db:mongoid:version") }
      invoke("db:mongoid:drop")
      assert_output("0\n") { invoke("db:mongoid:version") }
    end

    def test_drop_multidatabase
      Mongoid::Migrator.migrations_path = [MIGRATIONS_ROOT + "/multi_shards"]
      invoke("db:mongoid:migrate")
      assert_output("20210210125800\n") { invoke("db:mongoid:version") }
      with_env("MONGOID_CLIENT_NAME" => "shard1") do
        invoke("db:mongoid:migrate")
        assert_output("20210210125532\n") { invoke("db:mongoid:version") }
      end
      invoke("db:mongoid:drop")
      assert_output("0\n") { invoke("db:mongoid:version") }
      with_env("MONGOID_CLIENT_NAME" => "shard1") { assert_output("20210210125532\n") { invoke("db:mongoid:version") } }
    end


    def test_drop_multidatabase_on_target_client
      Mongoid::Migrator.migrations_path = [MIGRATIONS_ROOT + "/multi_shards"]
      invoke("db:mongoid:migrate")
      assert_output("20210210125800\n") { invoke("db:mongoid:version") }
      with_env("MONGOID_CLIENT_NAME" => "shard1") do
        invoke("db:mongoid:migrate")
        assert_output("20210210125532\n") { invoke("db:mongoid:version") }
        invoke("db:mongoid:drop")
        assert_output("0\n") { invoke("db:mongoid:version") }
      end
      assert_output("20210210125800\n") { invoke("db:mongoid:version") }
    end
  end
end
