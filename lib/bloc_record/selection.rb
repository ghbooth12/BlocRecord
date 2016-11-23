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
    return self if args == []

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

  def not(hash)
    str_condition = hash.map {|k,v| "#{k} != '#{v}'"}.join(" AND ")
    where(str_condition)
  end

  # This method is chained after ".joins" method.
  # query: the JOIN query
  # str: the new query
  def inner_where(query, str)
    sql = <<-SQL
      SELECT * FROM #{table}
      #{query}
      WHERE #{str};
    SQL
    rows = connection.execute(sql)
  end

  # Binary search is one example of an algorithm where the order is important.
  # This class method allows ordering by a String or Symbol.
  # 1) Sting conditions: Entry.order("phone_number"), Entry.order("phone_number, name")
  # 2) Hash conditions: Entry.order(:phone_number)
  # 3) Array conditions: Entry.order("name", "phone_number"), Entry.order(:name, :phone_number)
  def order(*args)
    orders = {}
    for arg in args
      case arg
      when String
        orders.merge!(string_order(arg)) # merge: a way to combine hashes.
      when Symbol
        orders[arg] = nil
      when Hash
        orders.merge!(arg)
      end
    end

    # e.g. orders = {:name=>nil, :phone_number=>:desc}
    # e.g. orders = {"name"=>"asc", "phone_number": "desc"}
    order_by = hash_to_str(orders)

    rows = connection.execute <<-SQL
      SELECT * FROM #{table}
      ORDER BY #{order_by};
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

  def joins(hash)
    join_1 = hash.keys[0]
    join_2 = hash.values[0]

    joins = "INNER JOIN #{join_1} ON #{join_1}.#{table}_id = #{table}.id " +
            "INNER JOIN #{join_2} ON #{join_2}.#{join_1}_id = #{join_1}.id"

    rows = connection.execute <<-SQL
      SELECT * FROM #{table}
      #{joins}
    SQL

    arr = rows_to_array(rows)
    arr.unshift(joins)  # To save the JOIN query
    arr
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

  # This method takes multiple conditions in string and returns a hash of multiple conditions.
  # e.g. str = "name ASC, phone_number DESC", "name", "name ASC" ...
  def string_order(str)
    orders = {}
    conditions = str.split(',')
    if conditions.count > 1  # multiple conditions
      for condition in conditions
        orders.merge!(divide_string(condition))
      end
    else # single condition
      condition = conditions[0]
      orders.merge!(divide_string(condition))
    end
    orders
  end

  # This method takes a single condition in string and returns a hash of a single condition.
  def divide_string(s)
    orders = {}
    str = s.downcase  # To change "ASC" to "asc", "DESC" to "desc"
    if str.include?(" asc") || str.include?(" desc")  # Note: a space before asc/desc
      pair = str.split(' ')  # pair = ["name", "asc"]
      orders[pair[0]] = pair[-1]
    else
      orders[str] = nil
    end
    orders
  end

  # This method changes a hash in a string format.
  def hash_to_str(hash)
    hash.map {|key, val| "#{key} #{val}"}.join(", ")
  end
end
