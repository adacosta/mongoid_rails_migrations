$:.unshift(File.dirname(__FILE__))

require File.dirname(__FILE__) + "/test/config"

namespace :test do
  namespace :mongoid do
    desc "Test mongoid rails migrations"
    task :migrations do
      require 'test/migration_test'
    end
  end
end