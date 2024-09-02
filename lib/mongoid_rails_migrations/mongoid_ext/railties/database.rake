namespace :db do
  desc 'Current database version'
  task :version => :environment do
    puts Mongoid::Migrator.current_version.to_s
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
        Rake::Task["db:migrate:down"].invoke
        Rake::Task["db:migrate:up"].invoke
      else
        Rake::Task["db:rollback"].invoke
        Rake::Task["db:migrate"].invoke
      end
    end

    desc 'Resets your database using your migrations for the current environment'
    # should db:create be changed to db:setup? It makes more sense wanting to seed
    task :reset => ["db:drop", "db:create", "db:migrate"]

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
end
