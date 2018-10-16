require "active_record"

namespace :db do
  namespace :migrate do
    desc "Check the reversibility of migration files"
    task check_reversibility: :load_config do
      config = ActiveRecord::Base.configurations.fetch(Rails.env)

      # Use a temporary database
      config["database"] += "_tmp"

      ActiveRecord::Tasks::DatabaseTasks.create(config)
      ActiveRecord::Tasks::DatabaseTasks.drop(config)
    end
  end
end
