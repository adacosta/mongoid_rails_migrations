require_relative './task_test_base'

module Mongoid
  class VersionTaskTest < TaskTestBase
    def test_database_version
      Mongoid::Migrator.migrations_path = [MIGRATIONS_ROOT + "/valid"]
      assert_output("0\n") { invoke("db:version") }
      invoke("db:migrate")
      assert_output("20100513063902\n") { invoke("db:version") }
      invoke("db:drop")
      assert_output("0\n") { invoke("db:version") }
    end

    def test_multidatabase_version
      Mongoid::Migrator.migrations_path = [MIGRATIONS_ROOT + "/multi_database"]
      assert_output("0\n") { invoke("db:version") }
      invoke("db:migrate")
      assert_output("20210210125800\n") { invoke("db:version") }
      invoke("db:drop")
      assert_output("0\n") { invoke("db:version") }
    end

    def test_multidatabase_version_with_target_client
      Mongoid::Migrator.migrations_path = [MIGRATIONS_ROOT + "/multi_database"]
      with_env("MONGOID_CLIENT_NAME" => "shard1") do
        assert_output("0\n") { invoke("db:version") }
        invoke("db:migrate")
        assert_output("20210210125532\n") { invoke("db:version") }
        invoke("db:drop")
        assert_output("0\n") { invoke("db:version") }
      end
    end
  end
end
