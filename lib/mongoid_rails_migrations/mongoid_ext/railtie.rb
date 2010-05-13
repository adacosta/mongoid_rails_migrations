# encoding: utf-8
require 'mongoid/railtie'

if defined?(Rails::Railtie)
  module Rails #:nodoc:
    module Mongoid #:nodoc:
      class Railtie < Rails::Railtie
        # should this have migration as true?
        config.generators.orm :mongoid, :migration => true

        rake_tasks do
          load "mongoid_rails_migrations/mongoid_ext/railties/database.rake"
        end
      end
    end
  end
end