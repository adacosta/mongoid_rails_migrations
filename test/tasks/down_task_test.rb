require_relative './task_test_base'

module Mongoid
  class DownTaskTest < TaskTestBase
    def test_database_migrate_down_raise_without_version
      assert_raises { invoke("db:mongoid:migrate:down") }
    end

    def test_database_migrate_down
      Mongoid::Migrator.migrations_path = [MIGRATIONS_ROOT + "/valid"]
      invoke("db:mongoid:migrate")
      assert_output(<<-EOF

database: mongoid_test

 Status   Migration ID    Migration Name
--------------------------------------------------
   up     20100513054656  AddBaselineSurveySchema
   up     20100513055502  AddSecondSurveySchema
   up     20100513063902  AddImprovementPlanSurveySchema
EOF
      ) { invoke("db:mongoid:migrate:status") }
      with_env("VERSION" => "20100513055502") do
        invoke("db:mongoid:migrate:down")
      end
      assert_output(<<-EOF

database: mongoid_test

 Status   Migration ID    Migration Name
--------------------------------------------------
   up     20100513054656  AddBaselineSurveySchema
  down    20100513055502  AddSecondSurveySchema
   up     20100513063902  AddImprovementPlanSurveySchema
EOF
      ) { invoke("db:mongoid:migrate:status") }
    end

    def test_multidatabase_migrate_down
      Mongoid::Migrator.migrations_path = [MIGRATIONS_ROOT + "/multi_shards"]
      invoke("db:mongoid:migrate")
      with_env("MONGOID_CLIENT_NAME" => "shard1") do
        invoke("db:mongoid:migrate")
      end

      output = <<-EOF

database: mongoid_test

 Status   Migration ID    Migration Name
--------------------------------------------------
   up     20210210125000  DefaultDatabaseMigration
   up     20210210125800  DefaultDatabaseMigrationTwo
EOF
      assert_output(output) { invoke("db:mongoid:migrate:status") }
      output = <<-EOF

database: mongoid_test_s1

 Status   Migration ID    Migration Name
--------------------------------------------------
   up     20210210124656  ShardDatabaseMigration
   up     20210210125532  ShardDatabaseMigrationTwo
EOF

      with_env("MONGOID_CLIENT_NAME" => "shard1") do
        assert_output(output) { invoke("db:mongoid:migrate:status") }
      end
      with_env("VERSION" => "20210210125000") do
        invoke("db:mongoid:migrate:down")
      end
      output = <<-EOF

database: mongoid_test_s1

 Status   Migration ID    Migration Name
--------------------------------------------------
   up     20210210124656  ShardDatabaseMigration
   up     20210210125532  ShardDatabaseMigrationTwo
EOF
      with_env("MONGOID_CLIENT_NAME" => "shard1") do
        assert_output(output) { invoke("db:mongoid:migrate:status") }
      end
      output = <<-EOF

database: mongoid_test

 Status   Migration ID    Migration Name
--------------------------------------------------
  down    20210210125000  DefaultDatabaseMigration
   up     20210210125800  DefaultDatabaseMigrationTwo
EOF
      assert_output(output) { invoke("db:mongoid:migrate:status") }
        assert_equal(1, DataMigration.count)
      Mongoid::Migrator.with_mongoid_client("shard1") do
        assert_equal(2, DataMigration.count)
      end
    end

    def test_multidatabase_migrate_down_on_target_client
      Mongoid::Migrator.migrations_path = [MIGRATIONS_ROOT + "/multi_shards"]
      invoke("db:mongoid:migrate")
      with_env("MONGOID_CLIENT_NAME" => "shard1") do
        invoke("db:mongoid:migrate")
      end

      output = <<-EOF

database: mongoid_test

 Status   Migration ID    Migration Name
--------------------------------------------------
   up     20210210125000  DefaultDatabaseMigration
   up     20210210125800  DefaultDatabaseMigrationTwo
EOF
      assert_output(output) { invoke("db:mongoid:migrate:status") }
      output = <<-EOF

database: mongoid_test_s1

 Status   Migration ID    Migration Name
--------------------------------------------------
   up     20210210124656  ShardDatabaseMigration
   up     20210210125532  ShardDatabaseMigrationTwo
EOF

      with_env("MONGOID_CLIENT_NAME" => "shard1", "VERSION" => "20210210124656") do
        assert_output(output) { invoke("db:mongoid:migrate:status") }
        invoke("db:mongoid:migrate:down")
        output = <<-EOF

database: mongoid_test_s1

 Status   Migration ID    Migration Name
--------------------------------------------------
  down    20210210124656  ShardDatabaseMigration
   up     20210210125532  ShardDatabaseMigrationTwo
EOF
        assert_output(output) { invoke("db:mongoid:migrate:status") }
      end
      output = <<-EOF

database: mongoid_test

 Status   Migration ID    Migration Name
--------------------------------------------------
   up     20210210125000  DefaultDatabaseMigration
   up     20210210125800  DefaultDatabaseMigrationTwo
EOF
      assert_output(output) { invoke("db:mongoid:migrate:status") }
      assert_equal(2, DataMigration.count)
      Mongoid::Migrator.with_mongoid_client("shard1") do
        assert_equal(1, DataMigration.count)
      end
    end
  end
end
