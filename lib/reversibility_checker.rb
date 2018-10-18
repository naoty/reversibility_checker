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
end
