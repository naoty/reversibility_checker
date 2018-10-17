require "active_record"
require "diffy"
require "stringio"

namespace :db do
  namespace :migrate do
    desc "Check the reversibility of migration files"
    task check_reversibility: :load_config do
      require "active_record/schema_dumper"

      config = ActiveRecord::Base.configurations.fetch(Rails.env)
      migrations_paths = ActiveRecord::Tasks::DatabaseTasks.migrations_paths

      ActiveRecord::Base.establish_connection(config)
      current_version = ActiveRecord::Migrator.current_version
      ActiveRecord::Base.remove_connection

      # Use a temporary database
      config["database"] += "_tmp"

      ActiveRecord::Tasks::DatabaseTasks.create(config)

      ActiveRecord::Base.establish_connection(config)
      ActiveRecord::Base.connection.migration_context.up(current_version)

      # Take a snapshot of the temporary schema
      current_buffer = StringIO.new
      ActiveRecord::SchemaDumper.dump(ActiveRecord::Base.connection, current_buffer)

      # Migrate a temporary schema upto latest
      ActiveRecord::Base.connection.migration_context.up
      ActiveRecord::Base.connection.migration_context.down(current_version)

      # Take a snapshot again
      rollbacked_buffer = StringIO.new
      ActiveRecord::SchemaDumper.dump(ActiveRecord::Base.connection, rollbacked_buffer)

      ActiveRecord::Tasks::DatabaseTasks.drop(config)

      # Compare two snapshots
      diff = Diffy::Diff.new(current_buffer.string, rollbacked_buffer.string)

      if diff.count > 0
        puts diff.to_s(:color)
        exit 1
      end

      puts "No diff"
    end
  end
end
