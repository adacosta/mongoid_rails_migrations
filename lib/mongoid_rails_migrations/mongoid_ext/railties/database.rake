namespace :mongoid do
  unless Rake::Task.task_defined?("mongoid:drop")
    desc 'Drops all the collections for the database for the current Rails.env'
    task :drop => :environment do
      Mongoid.master.collections.each {|col| col.drop_indexes && col.drop unless ['system.indexes', 'system.users'].include?(col.name) }
    end
  end

  unless Rake::Task.task_defined?("mongoid:seed")
    # if another ORM has defined mongoid:seed, don't run it twice.
    desc 'Load the seed data from mongoid/seeds.rb'
    task :seed => :environment do
      seed_file = File.join(Rails.application.root, 'mongoid', 'seeds.rb')
      load(seed_file) if File.exist?(seed_file)
    end
  end

  unless Rake::Task.task_defined?("mongoid:setup")
    desc 'Create the database, and initialize with the seed data'
    task :setup => [ 'mongoid:create', 'mongoid:seed' ]
  end

  unless Rake::Task.task_defined?("mongoid:reseed")
    desc 'Delete data and seed'
    task :reseed => [ 'mongoid:drop', 'mongoid:seed' ]
  end

  unless Rake::Task.task_defined?("mongoid:create")
    task :create => :environment do
      # noop
    end
  end

  desc 'Current database version'
  task :version => :environment do
    puts Mongoid::Migrator.current_version.to_s
  end

  desc "Migrate the database through scripts in db/mongoid/migrate. Target specific version with VERSION=x. Turn off output with VERBOSE=false."
  task :migrate => :environment do
    Mongoid::Migration.verbose = ENV["VERBOSE"] ? ENV["VERBOSE"] == "true" : true
    Mongoid::Migrator.migrate("db/mongoid/migrate/", ENV["VERSION"] ? ENV["VERSION"].to_i : nil)
  end

  namespace :migrate do
    desc  'Rollback the database one migration and re migrate up. If you want to rollback more than one step, define STEP=x. Target specific version with VERSION=x.'
    task :redo => :environment do
      if ENV["VERSION"]
        Rake::Task["mongoid:migrate:down"].invoke
        Rake::Task["mongoid:migrate:up"].invoke
      else
        Rake::Task["mongoid:rollback"].invoke
        Rake::Task["mongoid:migrate"].invoke
      end
    end

    desc 'Resets your database using your migrations for the current environment'
    # should mongoid:create be changed to mongoid:setup? It makes more sense wanting to seed
    task :reset => ["mongoid:drop", "mongoid:create", "mongoid:migrate"]

    desc 'Runs the "up" for a given migration VERSION.'
    task :up => :environment do
      version = ENV["VERSION"] ? ENV["VERSION"].to_i : nil
      raise "VERSION is required" unless version
      Mongoid::Migrator.run(:up, "mongoid/migrate/", version)
    end

    desc 'Runs the "down" for a given migration VERSION.'
    task :down => :environment do
      version = ENV["VERSION"] ? ENV["VERSION"].to_i : nil
      raise "VERSION is required" unless version
      Mongoid::Migrator.run(:down, "mongoid/migrate/", version)
    end
  end

  desc 'Rolls the database back to the previous migration. Specify the number of steps with STEP=n'
  task :rollback => :environment do
    step = ENV['STEP'] ? ENV['STEP'].to_i : 1
    Mongoid::Migrator.rollback('mongoid/migrate/', step)
  end

  namespace :schema do
    task :load do
      # noop
    end
  end

  namespace :test do
    task :prepare do
      # Stub out for Mongomongoid
    end
  end
end
