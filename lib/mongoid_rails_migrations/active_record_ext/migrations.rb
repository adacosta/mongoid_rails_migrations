# encoding: utf-8

module Mongoid #:nodoc
  # Exception that can be raised to stop migrations from going backwards.
  class IrreversibleMigration < RuntimeError
  end

  class DuplicateMigrationVersionError < RuntimeError#:nodoc:
    def initialize(version)
      super("Multiple migrations have the version number #{version}")
    end
  end

  class DuplicateMigrationNameError < RuntimeError#:nodoc:
    def initialize(name)
      super("Multiple migrations have the name #{name}")
    end
  end

  class UnknownMigrationVersionError < RuntimeError#:nodoc:
    def initialize(version)
      super("No migration with version number #{version}")
    end
  end

  class IllegalMigrationNameError < RuntimeError#:nodoc:
    def initialize(name)
      super("Illegal name for migration file: #{name}\n\t(only lower case letters, numbers, and '_' allowed)")
    end
  end

  # Data migrations can manage the modification of data. It's a solution to the common problem of modifying
  # data between code revisions within a document oriented database.
  #
  # Example of simple migration for a system dependency:
  #
  #   class AddBaselineSurveySchema < Mongoid::Migration
  #     def self.up
  #       SurveySchema.create(:label => 'Baseline Survey')
  #     end
  #
  #     def self.down
  #       SurveySchema.where(:label => 'Baseline Survey').first.destroy
  #     end
  #   end
  #
  # == Timestamped Migrations
  #
  # By default, Rails generates migrations that look like:
  #
  #    20080717013526_your_migration_name.rb
  #
  # The prefix is a generation timestamp (in UTC).
  #
  # If you'd prefer to use numeric prefixes, you can turn timestamped migrations
  # off by setting:
  #
  #    Mongoid.config.timestamped_migrations = false
  #
  # In environment.rb.
  #
  class Migration
    @@verbose = true
    cattr_accessor :verbose, :after_migrate, :buffer_output

    class << self
      def up_with_benchmarks #:nodoc:
        migrate(:up)
      end

      def down_with_benchmarks #:nodoc:
        migrate(:down)
      end

      # Execute this migration in the named direction
      def migrate(direction)
        return unless respond_to?(direction)

        case direction
          when :up   then announce "migrating"
          when :down then announce "reverting"
        end

        result = nil
        time = Benchmark.measure { result = send("#{direction}_without_benchmarks") }

        case direction
          when :up   then announce "migrated (%.4fs)" % time.real; write
          when :down then announce "reverted (%.4fs)" % time.real; write
        end

        begin
          @@after_migrate.call(@@buffer_output, name, direction, false) if @@after_migrate
          @@buffer_output = nil
        rescue => e
          say("Error in after_migrate hook: #{e}")
        end
        result
      end

      # Because the method added may do an alias_method, it can be invoked
      # recursively. We use @ignore_new_methods as a guard to indicate whether
      # it is safe for the call to proceed.
      def singleton_method_added(sym) #:nodoc:
        return if defined?(@ignore_new_methods) && @ignore_new_methods

        begin
          @ignore_new_methods = true

          case sym
            when :up, :down
              singleton_class.send(:alias_method, "#{sym}_without_benchmarks".to_sym, sym)
              singleton_class.send(:alias_method, sym, "#{sym}_with_benchmarks".to_sym)
          end
        ensure
          @ignore_new_methods = false
        end
      end

      def write(text="")
        @@buffer_output ||=  ""
        @@buffer_output += text + "\n"
        puts(text) if verbose
      end

      def announce(message)
        version = defined?(@version) ? @version : nil

        text = "#{version} #{name}: #{message}"
        length = [0, 75 - text.length].max
        write "== %s %s" % [text, "=" * length]
      end

      def say(message, subitem=false)
        write "#{subitem ? "   ->" : "--"} #{message}"
      end

      def say_with_time(message)
        say(message)
        result = nil
        time = Benchmark.measure { result = yield }
        say "%.4fs" % time.real, :subitem
        say("#{result} rows", :subitem) if result.is_a?(Integer)
        result
      end

      def suppress_messages
        save, self.verbose = verbose, false
        yield
      ensure
        self.verbose = save
      end

      def connection
        # ActiveRecord::Base.connection
        if ENV['MONGOID_CLIENT_NAME']
          Migrator.with_mongoid_client(ENV['MONGOID_CLIENT_NAME']) do
            Mongoid.client(Mongoid::Threaded.client_override)
          end
        else
          Mongoid.default_client
        end
      end

      def method_missing(method, *arguments, &block)
        arg_list = arguments.map(&:inspect) * ', '

        say_with_time "#{method}(#{arg_list})" do
          # unless arguments.empty? || method == :execute
          #   arguments[0] = Migrator.proper_table_name(arguments.first)
          # end
          connection.send(method, *arguments, &block)
        end
      end
    end
  end

  # MigrationProxy is used to defer loading of the actual migration classes
  # until they are needed
  class MigrationProxy

    attr_accessor :name, :version, :filename, :sharded

    delegate :migrate, :announce, :write, :to=>:migration

    private

      def migration
        @migration ||= load_migration
      end

      def load_migration
        require(File.expand_path(filename))
        name.constantize
      end

  end

  class Migrator#:nodoc:
    delegate :with_mongoid_client, :to => "self.class"

    class << self
      attr_writer :migrations_path

      def migrate(migrations_path, target_version = nil)
        case
          when target_version.nil?              then up(migrations_path, target_version)
          when current_version > target_version then down(migrations_path, target_version)
          else                                       up(migrations_path, target_version)
        end
      end

      def status(migrations_path)
        new(:up, migrations_path).status
      end

      def rollback(migrations_path, steps=1)
        move(:down, migrations_path, steps)
      end

      def rollback_to(migrations_path, target_version)
        all_versions = get_all_versions
        target_version_index = all_versions.index(target_version.to_i)
        raise UnknownMigrationVersionError.new(target_version) if target_version_index.nil?

        rollback_to = target_version_index + 1
        rollback_steps = all_versions.size - rollback_to
        rollback migrations_path, rollback_steps
      end

      def forward(migrations_path, steps=1)
        move(:up, migrations_path, steps)
      end

      def up(migrations_path, target_version = nil)
        self.new(:up, migrations_path, target_version).migrate
      end

      def down(migrations_path, target_version = nil)
        self.new(:down, migrations_path, target_version).migrate
      end

      def run(direction, migrations_path, target_version)
        self.new(direction, migrations_path, target_version).run
      end

      def migrations_path
        @migrations_path ||= ['db/migrate']
      end

      # def schema_migrations_table_name
      #   # Base.table_name_prefix + 'schema_migrations' + Base.table_name_suffix
      #   'data_migrations'
      # end

      def get_all_versions
        # table = Arel::Table.new(schema_migrations_table_name)
        #         Base.connection.select_values(table.project(table['version']).to_sql).map(&:to_i).sort
        with_mongoid_client(ENV['MONGOID_CLIENT_NAME']) do
          DataMigration.all.map { |datamigration| datamigration.version.to_i }.sort
        end
      end

      def current_version
        # sm_table = schema_migrations_table_name
        # if Base.connection.table_exists?(sm_table)
        #   get_all_versions.max || 0
        # else
        #   0
        # end
        get_all_versions.max || 0
      end

      def proper_table_name(name)
        # Use the Active Record objects own table_name, or pre/suffix from ActiveRecord::Base if name is a symbol/string
        # name.table_name rescue "#{ActiveRecord::Base.table_name_prefix}#{name}#{ActiveRecord::Base.table_name_suffix}"
        name
      end

      def with_mongoid_client(mongoid_client_name, &block)
        previous_mongoid_client_name = Mongoid::Threaded.client_override
        Mongoid.override_client(mongoid_client_name)
        block.call
      ensure
        Mongoid.override_client(previous_mongoid_client_name)
      end

      private

      def move(direction, migrations_path, steps)
        migrator = self.new(direction, migrations_path)
        start_index = migrator.migrations.index(migrator.current_migration)

        if start_index
          finish = migrator.migrations[start_index + steps]
          version = finish ? finish.version : 0
          send(direction, migrations_path, version)
        end
      end
    end

    def initialize(direction, migrations_path, target_version = nil)
      # raise StandardError.new("This database does not yet support migrations") unless Base.connection.supports_migrations?
      # Base.connection.initialize_schema_migrations_table
      @direction, @migrations_path, @target_version = direction, migrations_path, target_version

      @mongoid_client_name = ENV["MONGOID_CLIENT_NAME"]
      if @mongoid_client_name && !Mongoid.clients.has_key?(@mongoid_client_name)
        raise Mongoid::Errors::NoClientConfig.new(@mongoid_client_name)
      end
    end

    def current_version
      migrated.last || 0
    end

    def current_migration
      migrations.detect { |m| m.version == current_version }
    end


    def run
      target = migrations.detect { |m| m.version == @target_version }
      raise UnknownMigrationVersionError.new(@target_version) if target.nil?

      unless (up? && migrated.include?(target.version.to_i)) || (down? && !migrated.include?(target.version.to_i))
        target.migrate(@direction)
        with_mongoid_client(@mongoid_client_name) do
          record_version_state_after_migrating(target.version)
        end
      end
    end

    def migrate
      runnable = runnable_migrations

      runnable.each do |migration|
        Rails.logger.info "Migrating to #{migration.name} (#{migration.version})" if Rails.logger

        # On our way up, we skip migrating the ones we've already migrated
        next if up? && migrated.include?(migration.version.to_i)

        # On our way down, we skip reverting the ones we've never migrated
        if down? && !migrated.include?(migration.version.to_i)
          migration.announce 'never migrated, skipping'; migration.write
          next
        end

        # begin
        #   ddl_transaction do
        #     migration.migrate(@direction)
        #     record_version_state_after_migrating(migration.version)
        #   end
        # rescue => e
        #   canceled_msg = Base.connection.supports_ddl_transactions? ? "this and " : ""
        #   raise StandardError, "An error has occurred, #{canceled_msg}all later migrations canceled:\n\n#{e}", e.backtrace
        # end
        begin
          migration.migrate(@direction)
          with_mongoid_client(@mongoid_client_name) do
            record_version_state_after_migrating(migration.version)
          end
        rescue => e
          output = Migration.buffer_output + "An error has occurred, #{migration.version} and all later migrations canceled:\n\n#{e}\n#{e.backtrace.join("\n")}"
          begin
            Migration.after_migrate.call(output, migration.name, @direction, true) if Migration.after_migrate
            Migration.buffer_output = nil
          rescue => error
            puts("Error in after_migrate hook: #{error}")
          end
          raise StandardError, "An error has occurred, #{migration.version} and all later migrations canceled:\n\n#{e}", e.backtrace
        end
      end
    end

    def status
      database_name = Migration.connection.options[:database]
      puts "\ndatabase: #{database_name}\n\n"
      puts "#{'Status'.center(8)}  #{'Migration ID'.ljust(14)}  Migration Name"
      puts "-" * 50
      up_migrations = migrated.to_set
      migrations.each do |migration|
        status = up_migrations.include?(migration.version.to_i) ? 'up' : 'down'
        puts "#{status.center(8)}  #{migration.version.to_s.ljust(14)}  #{migration.name}"
      end
    end

    def migrations
      @migrations ||= begin
        files = Array(@migrations_path).inject([]) do |files, path|
          files += Dir["#{path}/**/[0-9]*_*.rb"]
        end

        migrations = files.inject([]) do |klasses, file|
          version, name = file.scan(/([0-9]+)_([_a-z0-9]*).rb/).first

          raise IllegalMigrationNameError.new(file) unless version
          version = version.to_i

          if klasses.detect { |m| m.version == version }
            raise DuplicateMigrationVersionError.new(version)
          end

          if klasses.detect { |m| m.name == name.camelize }
            raise DuplicateMigrationNameError.new(name.camelize)
          end

          migration = MigrationProxy.new
          migration.sharded  = file.match?(/\/shards\/#{version}_#{name}\.rb/)
          migration.name     = name.camelize
          migration.version  = version
          migration.filename = file

          if (@mongoid_client_name && migration.sharded) || (!@mongoid_client_name && !migration.sharded)
            klasses << migration
          end
          klasses
        end

        migrations = migrations.sort_by(&:version)
        down? ? migrations.reverse : migrations
      end
    end

    def pending_migrations
      already_migrated = migrated
      migrations.reject { |m| already_migrated.include?(m.version.to_i) }
    end

    def runnable_migrations
      current = migrations.detect { |m| m.version == current_version }
      target = migrations.detect { |m| m.version == @target_version }

      if target.nil? && !@target_version.nil? && @target_version > 0
        raise UnknownMigrationVersionError.new(@target_version)
      end

      start = up? ? 0 : (migrations.index(current) || 0)
      finish = migrations.index(target) || migrations.size - 1
      runnable = migrations[start..finish]

      # skip the last migration if we're headed down, but not ALL the way down
      runnable.pop if down? && !target.nil?

      runnable
    end

    def migrated
      @migrated_versions ||= self.class.get_all_versions
    end

    private
      def record_version_state_after_migrating(version)
        # table = Arel::Table.new(self.class.schema_migrations_table_name)

        @migrated_versions ||= []
        # if down?
        #   @migrated_versions.delete(version)
        #   table.where(table["version"].eq(version.to_s)).delete
        # else
        #   @migrated_versions.push(version).sort!
        #   table.insert table["version"] => version.to_s
        # end
        if down?
          @migrated_versions.delete(version)
          DataMigration.where(:version => version.to_s).destroy_all
        else
          @migrated_versions.push(version).sort!
          DataMigration.find_or_create_by(:version => version.to_s)
        end
      end

      def up?
        @direction == :up
      end

      def down?
        @direction == :down
      end

      # Wrap the migration in a transaction only if supported by the adapter.
      def ddl_transaction(&block)
        # if Base.connection.supports_ddl_transactions?
        #   Base.transaction { block.call }
        # else
        #   block.call
        # end
        block.call
      end
  end
end
