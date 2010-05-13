# encoding: utf-8

if defined?(Rails::Railtie)
  module Rails #:nodoc:
    module Mongoid #:nodoc:
      class Railtie < Rails::Railtie
        config.generators.orm :mongoid, :migration => true

        rake_tasks do
          load "mongoid_rails_migrations/mongoid_ext/railties/database.rake"
        end
      end
    end
  end
end