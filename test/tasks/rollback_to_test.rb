require_relative './task_test_base'

module Mongoid
  class RollbackToTest < TaskTestBase
    def test_database_rollback_raise_without_version
      assert_raises { invoke("db:mongoid:rollback_to") }
    end

    def test_database_rollback_to
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
      with_env("VERSION" => "20100513054656") { invoke("db:mongoid:rollback_to") }
      assert_output(<<-EOF

database: mongoid_test

 Status   Migration ID    Migration Name
--------------------------------------------------
   up     20100513054656  AddBaselineSurveySchema
  down    20100513055502  AddSecondSurveySchema
  down    20100513063902  AddImprovementPlanSurveySchema
EOF
      ) { invoke("db:mongoid:migrate:status") }
    end
  end

  def test_multidatabase_rollback_to
    Mongoid::Migrator.migrations_path = [MIGRATIONS_ROOT + "/multi_shards"]
    invoke("db:mongoid:migrate")
    output = <<-EOF

database: mongoid_test

Status   Migration ID    Migration Name
--------------------------------------------------
 up     20210210125000  DefaultDatabaseMigration
 up     20210210125800  DefaultDatabaseMigrationTwo
EOF
    assert_output(output) { invoke("db:mongoid:migrate:status") }
    with_env("MONGOID_CLIENT_NAME" => "shard1") do
      invoke("db:mongoid:migrate")
      assert_output(<<-EOF

database: mongoid_test_s1

Status   Migration ID    Migration Name
--------------------------------------------------
 up     20210210124656  ShardDatabaseMigration
 up     20210210125532  ShardDatabaseMigrationTwo
EOF
      ) { invoke("db:mongoid:migrate:status") }
    end
    with_env("VERSION" => "20210210125000") { invoke("db:mongoid:rollback_to") }
    output = <<-EOF

database: mongoid_test

Status   Migration ID    Migration Name
--------------------------------------------------
 up     20210210125000  DefaultDatabaseMigration
down    20210210125800  DefaultDatabaseMigrationTwo
EOF
    assert_output(output) { invoke("db:mongoid:migrate:status") }
    with_env("MONGOID_CLIENT_NAME" => "shard1") do
      assert_output(<<-EOF

database: mongoid_test_s1

Status   Migration ID    Migration Name
--------------------------------------------------
 up     20210210124656  ShardDatabaseMigration
 up     20210210125532  ShardDatabaseMigrationTwo
EOF
      ) { invoke("db:mongoid:migrate:status") }
    end

    def test_multidatabase_rollback_to_client_target
      Mongoid::Migrator.migrations_path = [MIGRATIONS_ROOT + "/multi_shards"]
      invoke("db:mongoid:migrate")
      output = <<-EOF

database: mongoid_test

 Status   Migration ID    Migration Name
--------------------------------------------------
   up     20210210125000  DefaultDatabaseMigration
   up     20210210125800  DefaultDatabaseMigrationTwo
EOF
      assert_output(output) { invoke("db:mongoid:migrate:status") }
      with_env("MONGOID_CLIENT_NAME" => "shard1") do
        invoke("db:mongoid:migrate")
        output = <<-EOF

database: mongoid_test_s1

 Status   Migration ID    Migration Name
--------------------------------------------------
   up     20210210124656  ShardDatabaseMigration
   up     20210210125532  ShardDatabaseMigrationTwo
EOF
        assert_output(output) { invoke("db:mongoid:migrate:status") }
        with_env("VERSION" => "20210210124656") { invoke("db:mongoid:rollback_to") }
        output = <<-EOF

database: mongoid_test_s1

 Status   Migration ID    Migration Name
--------------------------------------------------
   up     20210210124656  ShardDatabaseMigration
  down    20210210125532  ShardDatabaseMigrationTwo
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
    end
  end
end
