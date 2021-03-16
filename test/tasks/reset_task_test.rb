require_relative './task_test_base'

module Mongoid
  class ResetTaskTest < TaskTestBase
    def test_database_migrate_reset
      Mongoid::Migrator.migrations_path = [MIGRATIONS_ROOT + "/valid"]
      invoke("db:migrate")
      assert_output(<<-EOF

database: mongoid_test

 Status   Migration ID    Migration Name
--------------------------------------------------
   up     20100513054656  AddBaselineSurveySchema
   up     20100513055502  AddSecondSurveySchema
   up     20100513063902  AddImprovementPlanSurveySchema
EOF
      ) { invoke("db:migrate:status") }
      invoke("db:migrate:reset")
      assert_output(<<-EOF

database: mongoid_test

 Status   Migration ID    Migration Name
--------------------------------------------------
   up     20100513054656  AddBaselineSurveySchema
   up     20100513055502  AddSecondSurveySchema
   up     20100513063902  AddImprovementPlanSurveySchema
EOF
      ) { invoke("db:migrate:status") }
    end

    def test_multidatabase_migrate_reset
      Mongoid::Migrator.migrations_path = [MIGRATIONS_ROOT + "/multi_shards"]
      invoke("db:migrate")
      output = <<-EOF

database: mongoid_test

 Status   Migration ID    Migration Name
--------------------------------------------------
   up     20210210125000  DefaultDatabaseMigration
   up     20210210125800  DefaultDatabaseMigrationTwo
EOF
      assert_output(output) { invoke("db:migrate:status") }
      with_env("MONGOID_CLIENT_NAME" => "shard1") do
        invoke("db:migrate")
        assert_output(<<-EOF

database: mongoid_test_s1

 Status   Migration ID    Migration Name
--------------------------------------------------
   up     20210210124656  ShardDatabaseMigration
   up     20210210125532  ShardDatabaseMigrationTwo
EOF
        ) { invoke("db:migrate:status") }
      end
      invoke("db:migrate:reset")
      output = <<-EOF

database: mongoid_test

 Status   Migration ID    Migration Name
--------------------------------------------------
   up     20210210125000  DefaultDatabaseMigration
   up     20210210125800  DefaultDatabaseMigrationTwo
EOF
      assert_output(output) { invoke("db:migrate:status") }
      with_env("MONGOID_CLIENT_NAME" => "shard1") do
        assert_output(<<-EOF

database: mongoid_test_s1

 Status   Migration ID    Migration Name
--------------------------------------------------
   up     20210210124656  ShardDatabaseMigration
   up     20210210125532  ShardDatabaseMigrationTwo
EOF
        ) { invoke("db:migrate:status") }
      end
    end

    def test_multidatabase_migrate_reset_on_client_target
      Mongoid::Migrator.migrations_path = [MIGRATIONS_ROOT + "/multi_shards"]
      invoke("db:migrate")
      output = <<-EOF

database: mongoid_test

 Status   Migration ID    Migration Name
--------------------------------------------------
   up     20210210125000  DefaultDatabaseMigration
   up     20210210125800  DefaultDatabaseMigrationTwo
EOF
      assert_output(output) { invoke("db:migrate:status") }
      with_env("MONGOID_CLIENT_NAME" => "shard1") do
        invoke("db:migrate")
        output = <<-EOF

database: mongoid_test_s1

 Status   Migration ID    Migration Name
--------------------------------------------------
   up     20210210124656  ShardDatabaseMigration
   up     20210210125532  ShardDatabaseMigrationTwo
EOF
        assert_output(output) { invoke("db:migrate:status") }
        invoke("db:migrate:reset")
        assert_output(output) { invoke("db:migrate:status") }
      end
      output = <<-EOF

database: mongoid_test

 Status   Migration ID    Migration Name
--------------------------------------------------
   up     20210210125000  DefaultDatabaseMigration
   up     20210210125800  DefaultDatabaseMigrationTwo
EOF
      assert_output(output) { invoke("db:migrate:status") }
    end
  end
end
