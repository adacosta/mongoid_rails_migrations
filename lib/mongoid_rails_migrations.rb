# encoding: utf-8

require 'rubygems'
# Set up gems listed in the Gemfile.
if File.exist?(File.expand_path('../../Gemfile', __FILE__))
  require 'bundler'
  Bundler.setup
end

Bundler.require(:default) if defined?(Bundler)

# Add base to path incase not included as a gem
$:.unshift(File.dirname(__FILE__)) unless
  $:.include?(File.dirname(__FILE__)) || $:.include?(File.expand_path(File.dirname(__FILE__)))

require 'mongoid_rails_migrations/models/data_migration'
require 'mongoid_rails_migrations/mongoid_ext/mongoid'
require 'mongoid_rails_migrations/mongoid_ext/railtie'
require 'mongoid_rails_migrations/active_record_ext/migrations'