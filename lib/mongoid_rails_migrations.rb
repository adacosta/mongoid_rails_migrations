# encoding: utf-8

# Add base to path
$:.unshift(File.dirname(__FILE__)) unless
  $:.include?(File.dirname(__FILE__)) || $:.include?(File.expand_path(File.dirname(__FILE__)))

# Add rails generators to path
$:.unshift(File.dirname(__FILE__) + '/rails') unless
  $:.include?(File.dirname(__FILE__)  + '/rails') || $:.include?(File.expand_path(File.dirname(__FILE__)  + '/rails'))

require 'rubygems'
# Set up gems listed in the Gemfile.
if File.exist?(File.expand_path('../../Gemfile', __FILE__))
  require 'bundler'
  Bundler.setup
end

Bundler.require(:default) if defined?(Bundler)

# require 'rails'
# require 'railties'
# require 'activesupport'
# require 'mongoid'

require 'mongoid_rails_migrations/models/data_migration'
require 'mongoid_rails_migrations/mongoid_ext/mongoid'
require 'mongoid_rails_migrations/mongoid_ext/railtie'
require 'mongoid_rails_migrations/active_record_ext/migrations'