$:.unshift(File.dirname(__FILE__))

require 'bundler/setup'
Bundler.require(:test)

require 'mongoid'
require 'config'
require 'minitest/autorun'
require 'rake'
require 'rake/testtask'
require 'rdoc/task'

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


ActiveSupport.test_order = :sorted if ActiveSupport.respond_to?(:test_order)

module TestMongoidRailsMigrations
  class Application < Rails::Application; end
end

TestMongoidRailsMigrations::Application.load_tasks
