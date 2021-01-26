require_relative './task_test_base'

module Mongoid
  class RollbackTest < TaskTestBase
    def test_database_rollback
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
      invoke("db:rollback")
      assert_output(<<-EOF

database: mongoid_test

 Status   Migration ID    Migration Name
--------------------------------------------------
   up     20100513054656  AddBaselineSurveySchema
   up     20100513055502  AddSecondSurveySchema
  down    20100513063902  AddImprovementPlanSurveySchema
EOF
      ) { invoke("db:migrate:status") }
    end

    def test_database_rollback_step
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
      with_env("STEP" => "2") { invoke("db:rollback") }
      assert_output(<<-EOF

database: mongoid_test

 Status   Migration ID    Migration Name
--------------------------------------------------
   up     20100513054656  AddBaselineSurveySchema
  down    20100513055502  AddSecondSurveySchema
  down    20100513063902  AddImprovementPlanSurveySchema
EOF
      ) { invoke("db:migrate:status") }
    end

    def test_multidatabase_rollback
      Mongoid::Migrator.migrations_path = [MIGRATIONS_ROOT + "/multi_database"]
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
   up     20210210124656  Shard1DatabaseMigration
   up     20210210125532  Shard1DatabaseMigrationTwo
EOF
        ) { invoke("db:migrate:status") }
      end
      invoke("db:rollback")
      output = <<-EOF

database: mongoid_test

 Status   Migration ID    Migration Name
--------------------------------------------------
   up     20210210125000  DefaultDatabaseMigration
  down    20210210125800  DefaultDatabaseMigrationTwo
EOF
      assert_output(output) { invoke("db:migrate:status") }
      with_env("MONGOID_CLIENT_NAME" => "shard1") do
        assert_output(<<-EOF

database: mongoid_test_s1

 Status   Migration ID    Migration Name
--------------------------------------------------
   up     20210210124656  Shard1DatabaseMigration
   up     20210210125532  Shard1DatabaseMigrationTwo
EOF
        ) { invoke("db:migrate:status") }
      end
    end

    def test_multidatabase_rollback_on_client_target
      Mongoid::Migrator.migrations_path = [MIGRATIONS_ROOT + "/multi_database"]
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
   up     20210210124656  Shard1DatabaseMigration
   up     20210210125532  Shard1DatabaseMigrationTwo
EOF
        assert_output(output) { invoke("db:migrate:status") }
        invoke("db:rollback")
        output = <<-EOF

database: mongoid_test_s1

 Status   Migration ID    Migration Name
--------------------------------------------------
   up     20210210124656  Shard1DatabaseMigration
  down    20210210125532  Shard1DatabaseMigrationTwo
EOF
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
