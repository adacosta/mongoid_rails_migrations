$:.unshift(File.dirname(__FILE__))

require File.dirname(__FILE__) + "/test/config"

require 'rake/testtask'

namespace :test do
  namespace :mongoid do
    # Rake::TestTask.new(:migrations) do |t|
    #   # t.methods.sort.each {|i| puts i}
    #   # t.libs << "test"
    #   t.test_files = %w[ test/migration_test.rb ] 
    # end
    # Rake::Task['test:mongoid:migrations'].comment = "Test mongoid rails migrations"
    desc "Test mongoid rails migrations"
    task :migrations do
      # Rake::Task['gem:push'].invoke
      require 'migration_test'
    end
  end
end