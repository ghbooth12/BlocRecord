require 'sqlite3'

module Selection
  # This finds model objects when we know the id.
  # e.g. character = Character.find(7)
  def find(id)
    # Write a SQL query
    row = connection.get_first_row <<-SQL
      SELECT #{columns.join(",")} FROM #{table}
      WHERE id = #{id}
    SQL

    data = Hash[columns.zip(row)]
    # Return a new model object with the result(data(row))
    new(data)
  end
end
