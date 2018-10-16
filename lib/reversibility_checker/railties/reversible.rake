require "active_record"

namespace :db do
  namespace :migrate do
    desc "Check the reversibility of migration files"
    task check_reversibility: :load_config do
      config = ActiveRecord::Base.configurations.fetch(Rails.env)
      migrations_paths = ActiveRecord::Tasks::DatabaseTasks.migrations_paths

      ActiveRecord::Base.establish_connection(config)
      current_version = ActiveRecord::Migrator.current_version
      ActiveRecord::Base.remove_connection

      # Use a temporary database
      config["database"] += "_tmp"

      ActiveRecord::Tasks::DatabaseTasks.create(config)

      ActiveRecord::Base.establish_connection(config)
      ActiveRecord::Migrator.up(migrations_paths, current_version)

      ActiveRecord::Tasks::DatabaseTasks.drop(config)
    end
  end
end
