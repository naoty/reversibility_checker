require "active_record"

namespace :db do
  namespace :migrate do
    desc "Check the reversibility of migration files"
    task check_reversibility: :load_config do
    end
  end
end
