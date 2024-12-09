namespace :db do
  namespace :mongoid do
    if Rake::Task.task_defined?("db:mongoid:drop")
      Rake::Task["db:mongoid:drop"].clear
    end

    desc 'Drops the database for the current Mongoid client'
    task :drop => :environment do
      # Unlike Mongoid's default, this implementation supports the MONGOID_CLIENT_NAME override
      Mongoid::Migration.connection.database.drop
    end

    desc 'Current database version'
    task :version => :environment do
      puts Mongoid::Migrator.current_version.to_s
    end

    desc 'Rolls the database back to the previous migration. Specify the number of steps with STEP=n'
    task :rollback => :environment do
      step = ENV['STEP'] ? ENV['STEP'].to_i : 1
      Mongoid::Migrator.rollback(Mongoid::Migrator.migrations_path, step)
    end

    desc 'Rolls the database back to the specified VERSION'
    task :rollback_to => :environment do
      version = ENV["VERSION"] ? ENV["VERSION"].to_i : nil
      raise "VERSION is required" unless version
      Mongoid::Migrator.rollback_to(Mongoid::Migrator.migrations_path, version)
    end

    desc "Migrate the database through scripts in db/migrate. Target specific version with VERSION=x. Turn off output with VERBOSE=false."
    task :migrate => :environment do
      Mongoid::Migration.verbose = ENV["VERBOSE"] ? ENV["VERBOSE"] == "true" : true
      Mongoid::Migrator.migrate(Mongoid::Migrator.migrations_path, ENV["VERSION"] ? ENV["VERSION"].to_i : nil)
    end

    namespace :migrate do
      desc 'Rollback the database one migration and re migrate up. If you want to rollback more than one step, define STEP=x. Target specific version with VERSION=x.'
      task :redo => :environment do
        if ENV["VERSION"]
          Rake::Task["db:mongoid:migrate:down"].invoke
          Rake::Task["db:mongoid:migrate:up"].invoke
        else
          Rake::Task["db:mongoid:rollback"].invoke
          Rake::Task["db:mongoid:migrate"].invoke
        end
      end

      desc 'Resets your database using your migrations for the current environment'
      task :reset => ["db:mongoid:drop", "db:mongoid:migrate"]

      desc 'Runs the "up" for a given migration VERSION.'
      task :up => :environment do
        version = ENV["VERSION"] ? ENV["VERSION"].to_i : nil
        raise "VERSION is required" unless version
        Mongoid::Migrator.run(:up, Mongoid::Migrator.migrations_path, version)
      end

      desc 'Runs the "down" for a given migration VERSION.'
      task :down => :environment do
        version = ENV["VERSION"] ? ENV["VERSION"].to_i : nil
        raise "VERSION is required" unless version
        Mongoid::Migrator.run(:down, Mongoid::Migrator.migrations_path, version)
      end

      desc 'Display status of migrations'
      task :status => :environment do
        Mongoid::Migrator.status(Mongoid::Migrator.migrations_path)
      end
    end
  end

  unless Rake::Task.task_defined?("db:version")
    desc '[DEPRECATED] Use "db:mongoid:version" instead.'
    task :version => "db:mongoid:version"
  end

  unless Rake::Task.task_defined?("db:rollback")
    desc '[DEPRECATED] Use "db:mongoid:rollback" instead.'
    task :rollback => "db:mongoid:rollback"

    desc '[DEPRECATED] Use "db:mongoid:rollback_to" instead.'
    task :rollback_to => "db:mongoid:rollback_to"

    desc '[DEPRECATED] Use "db:mongoid:migrate" instead.'
    task :migrate => "db:mongoid:migrate"
  end

  namespace :migrate do
    unless Rake::Task.task_defined?("db:migrate:redo")
      desc '[DEPRECATED] Use "db:mongoid:migrate:redo" instead.'
      task :redo => "db:mongoid:migrate:redo"
    end

    unless Rake::Task.task_defined?("db:migrate:reset")
      desc '[DEPRECATED] Use "db:mongoid:migrate:reset" instead.'
      task :reset => "db:mongoid:migrate:reset"
    end

    unless Rake::Task.task_defined?("db:migrate:up")
      desc '[DEPRECATED] Use "db:mongoid:migrate:up" instead.'
      task :up => "db:mongoid:migrate:up"
    end

    unless Rake::Task.task_defined?("db:migrate:down")
      desc '[DEPRECATED] Use "db:mongoid:migrate:down" instead.'
      task :down => "db:mongoid:migrate:down"
    end

    unless Rake::Task.task_defined?("db:migrate:status")
      desc '[DEPRECATED] Use "db:mongoid:migrate:status" instead.'
      task :status => "db:mongoid:migrate:status"
    end
  end
end
