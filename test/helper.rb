$:.unshift(File.dirname(__FILE__)) unless
  $:.include?(File.dirname(__FILE__)) || $:.include?(File.expand_path(File.dirname(__FILE__)))

require 'config'
require 'test/unit'

require 'rake'
require 'rake/testtask'
require 'rake/rdoctask'

# leave out active_record, in favor of a monogo adapter
%w(
  action_controller
  action_mailer
  active_resource
  rails/test_unit
  mongoid
).each do |framework|
  begin
    require "#{framework}/railtie"
  rescue LoadError
  end
end

module TestMongoidRailsMigrations
  class Application < Rails::Application; end
end

# TestMongoidRailsMigrations::Application.initialize!
TestMongoidRailsMigrations::Application.load_tasks

# test overrides (dummy path); Rails is really looking for the app environment.rb
Rails.configuration.paths.config.environment = 'test/config.rb'