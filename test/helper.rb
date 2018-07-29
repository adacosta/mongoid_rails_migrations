require 'bundler/setup'
Bundler.require(:test)

# Dependencies
require 'mongoid_rails_migrations'
require 'rails/generators/mongoid/mongoid_generator'
require 'mongoid/railtie'
require 'minitest/autorun'

# Test setup
MIGRATIONS_ROOT = 'test/migrations'
Mongoid.configure.connect_to('mongoid_test')
require 'models/survey_schema'

module TestMongoidRailsMigrations
  class Application < Rails::Application; end
end

TestMongoidRailsMigrations::Application.load_tasks
