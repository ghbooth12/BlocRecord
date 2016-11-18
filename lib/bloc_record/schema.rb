# This contains information about the database schema.
# It translates between one SQL table and one Ruby class.

require 'sqlite3'
require 'bloc_record/utility'

module Schema

  # This method allows us to call 'table' on an object class to get its SQL table name.
  # e.g. BookAuthor.table would return book_author.
  def table
    BlocRecord::Utility.underscore(name)
  end

  def columns
    # We define schema momentarily as a hash with column names as keys, and types as values.
    # e.g. {"id" => "integer", "name" => "text", "age" => "integer"}
    # This columns method would return ["id", "name", "age"]
    schema.keys
  end

  def attributes
    # This would return ["name", "age"]
    # We use this for updating information.
    # Because generally we never change a record's id.
    columns - ["id"]
  end

  def schema
    # lazy loading: @schema isn't calculated until the first time it is needed.
    # (eager loading: @schema is calculated when the model object is initialized.)
    unless @schema
      @schema = {}
      connection.table_info(table) do |col|
        @schema[col["name"] = col["type"]]
      end
    end
    @schema
  end

  def count
    # Build connection between Ruby and SQL
    # <<- herodoc operator, SQL terminator
    # The text on the following lines up to the terminator is stored in a String
    # and used wherever the <<- is.
    # We passed the string to the execute method
    # execute is SQLite3::Database instand method.
    # It takes a SQL statement, executes it, and returns an array of rows(records),
    # each of which contains an array of columns.
    # [0][0] extracts the first column of the first row, which will contain the count.
    connection.execute(<<-SQL)[0][0]
      SELECT COUNT(*) FROM #{table}
    SQL

    # Same as above
    # connection.execute("SELECT COUNT(*) FROM #{table}")[0][0]
  end
end
