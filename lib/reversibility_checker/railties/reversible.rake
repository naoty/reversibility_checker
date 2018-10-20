require "active_record"
require "diffy"

namespace :db do
  namespace :migrate do
    desc "Check the reversibility of migration files"
    task check_reversibility: :load_config do
      require "active_record/schema_dumper"

      config = ActiveRecord::Base.configurations.fetch(Rails.env)
      current_version = ReversibilityChecker.current_schema_version(config)
      migrations_paths = ActiveRecord::Tasks::DatabaseTasks.migrations_paths

      # Use a temporary database
      config["database"] += "_tmp"

      # Suppress messages from db tasks
      $stdout = Tempfile.new

      ActiveRecord::Tasks::DatabaseTasks.create(config)
      at_exit { ActiveRecord::Tasks::DatabaseTasks.drop(config) }

      ActiveRecord::Base.establish_connection(config)
      ActiveRecord::Base.connection.migration_context.up(current_version)

      # Take a snapshot of the temporary schema
      current_schema = ReversibilityChecker.dump(config)

      # Migrate a temporary schema upto latest and rollback to current version
      ActiveRecord::Base.connection.migration_context.up
      ActiveRecord::Base.connection.migration_context.down(current_version)

      # Take a snapshot again
      rollbacked_schema = ReversibilityChecker.dump(config)

      # Compare two snapshots
      diff = Diffy::Diff.new(current_schema, rollbacked_schema)

      if diff.count > 0
        Object::STDOUT.puts diff.to_s(:color)
        exit 1
      end
    end
  end
end
