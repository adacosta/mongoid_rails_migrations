require_relative './task_test_base'

module Mongoid
  class MigrateTaskTest < TaskTestBase
    def test_database_migrate
      Mongoid::Migrator.migrations_path = [MIGRATIONS_ROOT + "/valid"]
      assert_output(<<-EOF

database: mongoid_test

 Status   Migration ID    Migration Name
--------------------------------------------------
  down    20100513054656  AddBaselineSurveySchema
  down    20100513055502  AddSecondSurveySchema
  down    20100513063902  AddImprovementPlanSurveySchema
EOF
      ) { invoke("db:mongoid:migrate:status") }
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
    end

    def test_database_migrate_with_version
      Mongoid::Migrator.migrations_path = [MIGRATIONS_ROOT + "/valid"]
      assert_output(<<-EOF

database: mongoid_test

 Status   Migration ID    Migration Name
--------------------------------------------------
  down    20100513054656  AddBaselineSurveySchema
  down    20100513055502  AddSecondSurveySchema
  down    20100513063902  AddImprovementPlanSurveySchema
EOF
      ) { invoke("db:mongoid:migrate:status") }
      with_env("VERSION" => "20100513055502") { invoke("db:mongoid:migrate") }
      assert_output(<<-EOF

database: mongoid_test

 Status   Migration ID    Migration Name
--------------------------------------------------
   up     20100513054656  AddBaselineSurveySchema
   up     20100513055502  AddSecondSurveySchema
  down    20100513063902  AddImprovementPlanSurveySchema
EOF
      ) { invoke("db:mongoid:migrate:status") }
    end


    def test_multidatabase_migrate
      Mongoid::Migrator.migrations_path = [MIGRATIONS_ROOT + "/multi_shards"]
      output = <<-EOF

database: mongoid_test

 Status   Migration ID    Migration Name
--------------------------------------------------
  down    20210210125000  DefaultDatabaseMigration
  down    20210210125800  DefaultDatabaseMigrationTwo
EOF
      assert_output(output) { invoke("db:mongoid:migrate:status") }
      output = <<-EOF

database: mongoid_test_s1

 Status   Migration ID    Migration Name
--------------------------------------------------
  down    20210210124656  ShardDatabaseMigration
  down    20210210125532  ShardDatabaseMigrationTwo
EOF

      invoke("db:mongoid:migrate")
      with_env("MONGOID_CLIENT_NAME" => "shard1") do
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
      assert_equal(2, SurveySchema.count)
      Mongoid::Migrator.with_mongoid_client("shard1") do
        assert_equal(0, DataMigration.count)
        assert_equal(0, SurveySchema.count)
      end
    end

    def test_multidatabase_migrate_on_target_client
      Mongoid::Migrator.migrations_path = [MIGRATIONS_ROOT + "/multi_shards"]
      output = <<-EOF

database: mongoid_test

 Status   Migration ID    Migration Name
--------------------------------------------------
  down    20210210125000  DefaultDatabaseMigration
  down    20210210125800  DefaultDatabaseMigrationTwo
EOF
      assert_output(output) { invoke("db:mongoid:migrate:status") }
      output = <<-EOF

database: mongoid_test_s1

 Status   Migration ID    Migration Name
--------------------------------------------------
  down    20210210124656  ShardDatabaseMigration
  down    20210210125532  ShardDatabaseMigrationTwo
EOF

      with_env("MONGOID_CLIENT_NAME" => "shard1") do
        assert_output(output) { invoke("db:mongoid:migrate:status") }
        invoke("db:mongoid:migrate")
        output = <<-EOF

database: mongoid_test_s1

 Status   Migration ID    Migration Name
--------------------------------------------------
   up     20210210124656  ShardDatabaseMigration
   up     20210210125532  ShardDatabaseMigrationTwo
EOF
        assert_output(output) { invoke("db:mongoid:migrate:status") }
      end
      output = <<-EOF

database: mongoid_test

 Status   Migration ID    Migration Name
--------------------------------------------------
  down    20210210125000  DefaultDatabaseMigration
  down    20210210125800  DefaultDatabaseMigrationTwo
EOF
      assert_output(output) { invoke("db:mongoid:migrate:status") }
      assert_equal(0, DataMigration.count)
      Mongoid::Migrator.with_mongoid_client("shard1") do
        assert_equal(2, DataMigration.count)
      end
    end
  end
end
