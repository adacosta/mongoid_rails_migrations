require 'rails/generators/mongoid/mongoid_generator'

module Mongoid
  module Generators
    class MigrationGenerator < Base
      argument :client_name, type: :string, optional: true, banner: "client_name"

      def create_migration_file
        migration_template "migration.rb", "db/migrate/#{file_name}.rb"
      end

      protected
        attr_reader :migration_action

    end
  end
end
