require 'rails/generators/mongoid/mongoid_generator'

module Mongoid
  module Generators
    class MigrationGenerator < Base
      class_option :shards, type: :boolean, optional: true, desc: "Create migration in shards subfolder"

      def create_migration_file
        destination_folder = "db/migrate"
        if options.fetch(:shards, Config.shards_migration_as_default)
          destination_folder = "#{destination_folder}/shards"
          FileUtils.mkdir_p("#{Rails.root}/#{destination_folder}")
        end

        migration_template "migration.rb", "#{destination_folder}/#{file_name}.rb"
      end

      protected
        attr_reader :migration_action

    end
  end
end
