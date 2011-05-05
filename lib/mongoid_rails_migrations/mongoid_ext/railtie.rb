# encoding: utf-8

if defined?(Rails::Railtie)
  module Rails #:nodoc:
    module Mongoid #:nodoc:
      class Railtie < Rails::Railtie
        def self.generator
          config.respond_to?(:app_generators) ? :app_generators : :generators
        end

        config.send(generator).orm :mongoid, :migration => true

        rake_tasks do
          load "mongoid_rails_migrations/mongoid_ext/railties/database.rake"
        end
      end
    end
  end
end