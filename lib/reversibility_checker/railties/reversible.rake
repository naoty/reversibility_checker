require "active_record"
require "diffy"

namespace :db do
  namespace :migrate do
    desc "Check the reversibility of migration files"
    task check_reversibility: :load_config do
      require "active_record/schema_dumper"

      config = ActiveRecord::Base.configurations.fetch(Rails.env)
      current_version = ReversibilityChecker.current_version(config)
      target_versions = ReversibilityChecker.target_versions(config, current_version)
      migrations_paths = ActiveRecord::Tasks::DatabaseTasks.migrations_paths

      # Use a temporary database
      config["database"] += "_tmp"

      # Suppress messages from db tasks
      $stdout = Tempfile.new

      ActiveRecord::Tasks::DatabaseTasks.create(config)
      ActiveRecord::Base.establish_connection(config)

      at_exit {
        ActiveRecord::Tasks::DatabaseTasks.drop(config)
        ActiveRecord::Base.remove_connection
      }

      reversible = true
      base_version = current_version

      target_versions.each do |target_version|
        ActiveRecord::Base.connection.migration_context.up(base_version)
        base_schema = ReversibilityChecker.dump(config)

        ActiveRecord::Base.connection.migration_context.up(target_version)
        ActiveRecord::Base.connection.migration_context.down(base_version)
        rollbacked_schema = ReversibilityChecker.dump(config)

        diff = Diffy::Diff.new(base_schema, rollbacked_schema)

        if diff.count > 0
          Object::STDOUT.puts "== +#{target_version} ============================================================"
          Object::STDOUT.puts diff.to_s(:color)
          Object::STDOUT.puts "== -#{base_version} ============================================================"
          Object::STDOUT.puts ""
          reversible = false
        end

        base_version = target_version
      end

      exit 1 unless reversible
    end
  end
end
