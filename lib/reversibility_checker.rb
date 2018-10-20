require "reversibility_checker/railtie"
require "reversibility_checker/version"

require "active_record"
require "stringio"

module ReversibilityChecker
  def self.dump(config)
    case ActiveRecord::Base.schema_format
    when :ruby
      buffer = StringIO.new
      ActiveRecord::SchemaDumper.dump(ActiveRecord::Base.connection, buffer)
      buffer.string
    when :sql
      file = Tempfile.new
      ActiveRecord::Tasks::DatabaseTasks.structure_dump(config, file.path)
      file.read
    end
  end

  def self.current_version(config)
    return ENV["CURRENT_VERSION"].to_i unless ENV["CURRENT_VERSION"].nil?

    ActiveRecord::Base.establish_connection(config)
    version = ActiveRecord::Migrator.current_version
    ActiveRecord::Base.remove_connection

    return version
  end

  def self.target_versions(config, current_version)
    ActiveRecord::Base.establish_connection(config)
    migration_context = ActiveRecord::Base.connection.migration_context
    ActiveRecord::Base.remove_connection

    versions = ActiveRecord::Tasks::DatabaseTasks.migrations_paths.flat_map do |migrations_path|
      Dir["#{migrations_path}/*.rb"].map do |filepath|
        migration_context.parse_migration_filename(filepath).first.to_i
      end
    end
    versions.select { |version| version > current_version }.sort
  end
end
