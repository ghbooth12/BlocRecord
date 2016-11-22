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

      rows_to_array(rows)
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

  def where(*args)
    # 1) Handle array conditions
    # e.g. Entry.where("phone_number = ?", params[:phone_number])
    if args.count > 1
      expression = args.shift # Removes the first element and returns it
      params = args
    else
      case args.first
      # 2) Handle string conditions
      # e.g. Entry.where("phone_number = '999-999-9999'")
      when String
        expression = args.first # It will be used directly in the WHERE clause.
      # 3) Handle hash conditions
      # e.g. Entry.where(name: 'BlocHead', age: 30)
      when Hash
        expression_hash = BlocRecord::Utility.convert_keys(args.first)
        expression = expression_hash.map {|key, value| "#{key}=#{BlocRecord::Utility.sql_strings(value)}"}.join(" and ")
      end
    end

    sql = <<-SQL
      SELECT #{columns.join(',')} FROM #{table}
      WHERE #{expression};
    SQL

    # params are passed in to connection.execute(), which handles "?" replacement.
    rows = connection.execute(sql, params)
    rows_to_array(rows)
  end

  # Binary search is one example of an algorithm where the order is important.
  # This class method allows ordering by a String or Symbol.
  # 1) Sting conditions: Entry.order("phone_number"), Entry.order("phone_number, name")
  # 2) Hash conditions: Entry.order(:phone_number)
  # 3) Array conditions: Entry.order("name", "phone_number"), Entry.order(:name, :phone_number)
  def order(*args)
    if args.count > 1
      order = args.join(",")
    else
      order = order.first.to_s  # If it's a Symbol, to_s coverts it to a string.
    end
    rows = connection.execute <<-SQL
      SELECT * FROM #{table}
      ORDER BY #{order};
    SQL
    rows_to_array(rows)
  end

  def join(*args)
    # 3) .join Multiple Association with Symbols
    # If more than one element is passed in, our query JOINs on multiple associations.
    if args.count > 1
      joins = args.map {|arg| "INNER JOIN #{arg} ON #{arg}.#{table}_id = #{table}.id"}.join(" ")
      rows = connection.execute <<-SQL
        SELECT * FROM #{table}
        #{joins}
      SQL
    else
      case args.first
      when String
        # 1) .join with String SQL
        # BlocRecord users pass in a handwritten JOIN statement like:
        # e.g. 'JOIN table_name ON some_condition'
        rows = connection.execute <<-SQL
          SELECT * FROM #{table}
          #{BlocRecord::Utility.sql_strings(args.first)};
        SQL
      when Symbol
        # 2) .join a single association with a Symbol
        # e.g. Employee.join(:Department) results in the query:
        # SELECT * FROM employee JOIN deparment ON department.employee_id = employee.id;
        # But this way should follow standard naming conventions.
        rows = connection.execute <<-SQL
          SELECT * FROM #{table}
          INNER JOIN #{args.first} ON #{args.first}.#{table}_id = #{table}.id;
        SQL
      end # Ends case
    end # Ends if-else
    rows_to_array(rows)
  end # Ends join()

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
