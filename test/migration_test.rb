require 'helper'

# Hide task output
class Mongoid::Migration
  def self.puts _
  end
end

module Mongoid
  class TestCase < Minitest::Test #:nodoc:

    def setup
      Mongoid::Migration.verbose = true
      Mongo::Logger.logger.level = 1
      # same as db:drop command in lib/mongoid_rails_migrations/mongoid_ext/railties/database.rake
      if Mongoid.respond_to?(:default_client)
        Mongoid.default_client.database.drop
      else
        Mongoid.default_session.drop
      end
    end

    def teardown
      Mongoid.configure.timestamped_migrations = true
    end

    def test_drop_works
      assert_equal 0, Mongoid::Migrator.current_version, "db:drop should take us down to version 0"
    end

    def test_migrations_path
      assert_equal ["db/migrate"], Mongoid::Migrator.migrations_path

      Mongoid::Migrator.migrations_path += ["engines/my_engine/db/migrate"]

      assert_equal ["db/migrate", "engines/my_engine/db/migrate"], Mongoid::Migrator.migrations_path
    end

    def test_finds_migrations
      assert Mongoid::Migrator.new(:up, MIGRATIONS_ROOT + "/valid").migrations.size == 3
      assert_equal 3, Mongoid::Migrator.new(:up, MIGRATIONS_ROOT + "/valid").pending_migrations.size
    end

    def test_finds_migrations_in_multiple_paths
      migration_paths = [MIGRATIONS_ROOT + "/valid", MIGRATIONS_ROOT + "/other_valid"]

      assert_equal 4, Mongoid::Migrator.new(:up, migration_paths).migrations.size
      assert_equal 4, Mongoid::Migrator.new(:up, migration_paths).pending_migrations.size
    end

    def test_migrator_current_version
      Mongoid::Migrator.migrate(MIGRATIONS_ROOT + "/valid", 20100513054656)
      assert_equal(20100513054656, Mongoid::Migrator.current_version)
    end

    def test_migrator
      assert SurveySchema.first.nil?, "All SurveySchemas should be clear before migration run"

      Mongoid::Migrator.up(MIGRATIONS_ROOT + "/valid")

      assert_equal 20100513063902, Mongoid::Migrator.current_version
      assert !SurveySchema.first.nil?

      Mongoid::Migrator.down(MIGRATIONS_ROOT + "/valid")
      assert_equal 0, Mongoid::Migrator.current_version

      assert SurveySchema.create(:label => 'Questionable Survey')
      assert_equal 1, SurveySchema.all.size
    end

    def test_migrator_two_up_and_one_down
      assert SurveySchema.where(:label => 'Baseline Survey').first.nil?
      assert_equal 0, SurveySchema.all.size

      Mongoid::Migrator.up(MIGRATIONS_ROOT + "/valid", 20100513054656)

      assert !SurveySchema.where(:label => 'Baseline Survey').first.nil?
      assert_equal 1, SurveySchema.all.size

      assert SurveySchema.where(:label => 'Improvement Plan Survey').first.nil?

      Mongoid::Migrator.up(MIGRATIONS_ROOT + "/valid", 20100513063902)
      assert_equal 20100513063902, Mongoid::Migrator.current_version

      assert !SurveySchema.where(:label => 'Improvement Plan Survey').first.nil?
      assert_equal 3, SurveySchema.all.size

      Mongoid::Migrator.down(MIGRATIONS_ROOT + "/valid", 20100513054656)
      assert_equal 20100513054656, Mongoid::Migrator.current_version

      assert SurveySchema.where(:label => 'Improvement Plan Survey').first.nil?
      assert !SurveySchema.where(:label => 'Baseline Survey').first.nil?
      assert_equal 1, SurveySchema.all.size
    end

    def test_finds_pending_migrations
      Mongoid::Migrator.up(MIGRATIONS_ROOT + "/valid", 20100513054656)
      pending_migrations = Mongoid::Migrator.new(:up, MIGRATIONS_ROOT + "/valid").pending_migrations

      assert_equal 2, pending_migrations.size
      assert_equal pending_migrations[1].version, 20100513063902
      assert_equal pending_migrations[1].name, 'AddImprovementPlanSurveySchema'
    end

    def test_migrator_rollback
      Mongoid::Migrator.migrate(MIGRATIONS_ROOT + "/valid")
      assert_equal(20100513063902, Mongoid::Migrator.current_version)

      Mongoid::Migrator.rollback(MIGRATIONS_ROOT + "/valid")
      assert_equal(20100513055502, Mongoid::Migrator.current_version)

      Mongoid::Migrator.rollback(MIGRATIONS_ROOT + "/valid")
      assert_equal(20100513054656, Mongoid::Migrator.current_version)

      Mongoid::Migrator.rollback(MIGRATIONS_ROOT + "/valid")
      assert_equal(0, Mongoid::Migrator.current_version)
    end

    def test_migrator_rollback_to
      Mongoid::Migrator.migrate(MIGRATIONS_ROOT + "/valid")
      assert_equal(20100513063902, Mongoid::Migrator.current_version)

      Mongoid::Migrator.rollback_to(MIGRATIONS_ROOT + "/valid", 20100513054656)
      assert_equal(20100513054656, Mongoid::Migrator.current_version)
    end

    def test_migrator_forward
      Mongoid::Migrator.migrate(MIGRATIONS_ROOT + "/valid", 20100513054656)
      assert_equal(20100513054656, Mongoid::Migrator.current_version)

      Mongoid::Migrator.forward(MIGRATIONS_ROOT + "/valid", 20100513063902)
      assert_equal(20100513063902, Mongoid::Migrator.current_version)
    end

    def test_migrator_with_duplicate_names
      assert_raises(Mongoid::DuplicateMigrationNameError) do
        Mongoid::Migrator.migrate(MIGRATIONS_ROOT + "/duplicate/names", nil)
      end
    end

    def test_migrator_with_duplicate_versions
      assert_raises(Mongoid::DuplicateMigrationVersionError) do
        Mongoid::Migrator.migrate(MIGRATIONS_ROOT + "/duplicate/versions", nil)
      end
    end

    def test_migrator_with_missing_version_numbers
      assert_raises(Mongoid::UnknownMigrationVersionError) do
        Mongoid::Migrator.migrate(MIGRATIONS_ROOT + "/valid", 500)
      end
    end

    def test_default_state_of_timestamped_migrations
      assert Mongoid.configure.timestamped_migrations, "Mongoid.configure.timestamped_migrations should default to true"
    end

    def test_timestamped_migrations_generates_non_sequential_next_number
      next_number = Mongoid::Generators::Base.next_migration_number(MIGRATIONS_ROOT + "/valid")
      refute_equal "20100513063903", next_number
    end

    def test_turning_off_timestamped_migrations
      Mongoid.configure.timestamped_migrations = false
      next_number = Mongoid::Generators::Base.next_migration_number(MIGRATIONS_ROOT + "/valid")
      assert_equal "20100513063903", next_number
    end

    def test_migration_returns_connection_without_error
      Mongoid::Migration.connection
    end

    def test_status_with_all_pending_migrations
      output = <<-EOF

database: mongoid_test

 Status   Migration ID    Migration Name
--------------------------------------------------
  down    20100513054656  AddBaselineSurveySchema
  down    20100513055502  AddSecondSurveySchema
  down    20100513063902  AddImprovementPlanSurveySchema
      EOF
      assert_output(output) { Mongoid::Migrator.status(MIGRATIONS_ROOT + "/valid") }
    end

    def test_status_with_some_pending_migrations
      Mongoid::Migrator.migrate(MIGRATIONS_ROOT + "/valid", 20100513054656)
      output = <<-EOF

database: mongoid_test

 Status   Migration ID    Migration Name
--------------------------------------------------
   up     20100513054656  AddBaselineSurveySchema
  down    20100513055502  AddSecondSurveySchema
  down    20100513063902  AddImprovementPlanSurveySchema
      EOF
      assert_output(output) { Mongoid::Migrator.status(MIGRATIONS_ROOT + "/valid") }
    end

    def test_status_with_a_middle_pending_migrations
      Mongoid::Migrator.migrate(MIGRATIONS_ROOT + "/valid")
      Mongoid::Migrator.run(:down, MIGRATIONS_ROOT + "/valid", 20100513055502)
      output = <<-EOF

database: mongoid_test

 Status   Migration ID    Migration Name
--------------------------------------------------
   up     20100513054656  AddBaselineSurveySchema
  down    20100513055502  AddSecondSurveySchema
   up     20100513063902  AddImprovementPlanSurveySchema
      EOF
      assert_output(output) { Mongoid::Migrator.status(MIGRATIONS_ROOT + "/valid") }
    end

    def test_status_without_pending_migrations
      Mongoid::Migrator.migrate(MIGRATIONS_ROOT + "/valid")
      output = <<-EOF

database: mongoid_test

 Status   Migration ID    Migration Name
--------------------------------------------------
   up     20100513054656  AddBaselineSurveySchema
   up     20100513055502  AddSecondSurveySchema
   up     20100513063902  AddImprovementPlanSurveySchema
      EOF
      assert_output(output) { Mongoid::Migrator.status(MIGRATIONS_ROOT + "/valid") }
    end

  end
end
