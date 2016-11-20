require 'sqlite3'

module Selection
  # This method can handle multiple ids using the splat operator.
  # splat operator combines any number of arguments inito an array.
  # e.g. find(4, 8, 11) will be ids = [4, 8, 11]
  # This method returns either one model object or an array.
  def find(*ids)
    if ids.length == 1
      find_one(ids.first)
    else # The objects are compounded into an array.
      rows = connection.execute(<<-SQL)
        SELECT #{columns.join(',')} FROM #{table}
        WHERE id IN (#{ids.join(',')});
      SQL

      row_to_array(rows)
    end
  end

  # This finds model objects when we know the id.
  # e.g. character = Character.find(7)
  def find_one(id)
    # Write a SQL query
    row = connection.get_first_row <<-SQL
      SELECT #{columns.join(",")} FROM #{table}
      WHERE id = #{id}
    SQL

    init_object_from_row(row)
  end

  def find_by(attribute, value)
    row = connection.get_first_row(<<-SQL)
      SELECT #{columns.join(',')} FROM #{table}
      WHERE #{attribute} = #{BlocRecord::Utility.sql_strings(value)};
    SQL

    init_object_from_row(row)
  end

  # This method returns either one model object or an array.
  def take(num=1)
    if num > 1
      # Note: LIMIT #{num}. Because random() is a SQL core function so it isn't wrapped with #{}.
      # num is NOT a SQL function. So it needs to wrap with #{}.
      rows = connection.exectue(<<-SQL)
        SELECT #{columns.join(',')} FROM #{table}
        ORDER BY random()
        LIMIT #{num};
      SQL

      rows_to_array(rows)
    else
      take_one
    end
  end

  def take_one
    # The random() function returns a pseudo-random integer between -9223372036854775808 and +9223372036854775807.
    row = connection.get_first_row(<<-SQL)
    SELECT #{columns.join(',')} FROM #{table}
    ORDER BY random()
    LIMIT 1;
    SQL

    init_object_from_row(row)
  end

  def first
    row = connection.get_first_row(<<-SQL)
      SELECT #{columns.join(',')} FROM #{table}
      ORDER BY id ASC
      LIMIT 1;
    SQL

    init_object_from_row(row)
  end

  def last
    row = connection.get_first_row(<<-SQL)
      SELECT #{columns.join(',')} FROM #{table}
      ORDER BY id DESC
      LIMIT 1;
    SQL

    init_object_from_row(row)
  end

  def all
    rows = connection.execute(<<-SQL)
      SELECT #{columns.join(',')} FROM #{table};
    SQL

    rows_to_array(rows)
  end

  private
  def init_object_from_row(row)
    if row
      data = Hash[columns.zip(row)]
      new(data)
    end
  end

  # This method maps the rows to an array of corresponding model objects.
  def rows_to_array(rows)
    rows.map { |row| new(Hash[columns.zip(row)]) }
  end
end
