require 'bundler/setup'
Bundler.require(:test)

# Dependencies
require 'mongoid_rails_migrations'
require 'rails/generators/mongoid/mongoid_generator'
require 'mongoid/railtie'
require 'minitest/autorun'

# Test setup
MIGRATIONS_ROOT = 'test/migrations'

Mongoid.load_configuration(clients: {
  default: { hosts: ['localhost:27017'], database: 'mongoid_test' },
  shard1: { hosts: ['localhost:27017'], database: 'mongoid_test_s1' }
})

require_relative 'models/survey_schema'

module TestMongoidRailsMigrations
  class Application < Rails::Application; end
end

TestMongoidRailsMigrations::Application.load_tasks

# Hide task output
class Mongoid::Migration
  def self.puts _
  end
end

def invoke(task)
  Rake.application.tasks.each(&:reenable)
  Rake::Task[task].invoke
end

def with_env(options)
  options.keys.each { |key| ENV[key] = options[key] }
  yield
ensure
  options.keys.each { |key| ENV.delete(key) }
end
