# To create a record
# This module must work directly with the database and understand the schema.

require 'sqlite3'
require 'bloc_record/schema'
require 'bloc_record/validation'

module Persistence
  def method_missing(m, *args, &block)
    if m == :update_name
      update_attribute(:name, args[0])
    end
  end

  # self.included is called whenever this module is included.
  # When this haapens, extend adds the ClassMethods methods to Persistence.
  def self.included(base)
    base.extend(ClassMethods)
  end

  # save method needs to be an instance method. So "save" can be called on an object.
  def save!
    unless self.id
      self.id = self.class.create(BlocRecord::Utility.instance_variables_to_hash(self)).id
      # We call reload_obj to copy whatever is stored in the database back to the model object.
      # This is necessary in case SQL rejected or changed any of the data.
      BlocRecord::Utility.reload_obj(self)
      return true # When created, save! ends.
    end

    # self.id exists, which means the existing 'data' is edited.
    fields = self.class.attributes.map { |col|
      "#{col}=#{BlocRecord::Utility.sql_strings(self.instance_variable_get("@#{col}"))}"
    }.join(",")

    self.class.connection.execute <<-SQL
      UPDATE #{self.class.table}
      SET #{fields}
      WHERE id = #{self.id};
    SQL

    true
  end

  # save method needs to be an instance method. So "save" can be called on an object.
  def save
    self.save! rescue false
  end

  # Update One Attribute With an Instance Method
  # e.g. p = Person.first
  # p.update_attribute(:name, "Ben")
  def update_attribute(attribute, value)
    self.class.update(self.id, { attribute => value })
  end

  # Update Multiple Attributes With an Instance Method
  # This updates multiple attributes at once.
  # p = Person.first
  # p.update_attributes(name: "Ben", age: 30)
  def update_attributes(updates)
    self.class.update(self.id, updates)
  end

  # e = Entry.first
  # e.destroy
  def destroy
    self.class.destroy(self.id)
  end

  # create method needs to be a class method. Because we can't call "create" on an object which doesn't exist.
  module ClassMethods
    # attrs is a hash just like the one in the base class initializer.
    # Its values are converted to SQL strings and mapped into an array(vals).
    # e.g. Character.create({"name"=>"Jar-Jar Binks", "rating"=>1})
    # vals would become ["'Jar-Jar Binks'", "1"]
    # INSERT INTO character (name, rating)
    # VALUES ('Jar-Jar Binks', 1)
    def create(attrs)
      attrs = BlocRecord::Utility.convert_keys(attrs)
      begin
        if Validation.validate(schema, attrs)
          attrs.delete("id")
          vals = attributes.map {|key| BlocRecord::Utility.sql_strings(attrs[key])}
          connection.execute <<-SQL
            INSERT INTO #{table} (#{attributes.join(",")})
            VALUES (#{vals.join(",")});
          SQL

          data = Hash[attributes.zip(attrs.values)]
          data["id"] = connection.execute("SELECT last_insert_rowid();")[0][0]
          new(data)
        else
          raise "Invalid Input for table(#{table})"
        end
      rescue Exception => e
        puts e.message
        # puts e.backtrace.inspect
      end
    end

    # Update Multiple Attributes With a Class Method
    # e.g. Person.update(15, student: false, group: 'member')
    # "ids" can be a number or an array of numbers.
    def update(ids, updates)
      # people = { 1 => { "first_name" => "David" }, 2 => { "first_name" => "Jeremy" } }
      # Person.update(people.keys, people.values)
      if ids.class == Array && updates.class == Array
        # Each item in "people" executes SQL statement.
        for i in 0...ids.length
          updates_array = []
          hash = updates[i]  # hash: { "first_name" => "David", "age" => 30 }

          for key in hash.keys  # hash.keys: ["first_name", "age"]
            updates_array << "#{key}=#{BlocRecord::Utility.sql_strings(hash[key])}"
          end

          connection.execute <<-SQL
            UPDATE #{table} SET #{updates_array * ','}
            WHERE id = #{ids[i]}
          SQL
        end

        return true
      end

      updates = BlocRecord::Utility.convert_keys(updates)
      updates.delete "id"

      updates_array = updates.map {|key, value| "#{key}=#{BlocRecord::Utility.sql_strings(value)}"}

      if ids.class == Fixnum
        where_clause = "WHERE id = #{ids};"
      elsif ids.class == Array
        where_clause = ids.empty? ? ";" : "WHERE id IN (#{ids.join(',')});"
      else # When update_all is executed, id is nil.
        where_clause = ";"
      end

      # updates_array * ',' == updates_array.join(',')
      connection.execute <<-SQL
        UPDATE #{table}
        SET #{updates_array * ','}
        #{where_clause}
      SQL

      true
    end # Ends update

    # Update Multiple Attributes on All Records
    def update_all(updates)
      update(nil, updates)
    end

    # Class Method to Delete One Item / Multiple Items
    # Entry.destroy(15) / Entry.destroy(1, 2, 3)
    def destroy(*ids)
      if ids.length > 1
        where_clause = "WHERE id IN (#{ids.join(',')});"
      else
        where_clause = "WHERE id = #{id.first};"
      end

      connection.execute <<-SQL
        DELETE FROM #{table}
        #{where_clause}
      SQL

      true
    end

    # Entry.destroy_all
    # Entry.destroy_all(age: 20)
    def destroy_all(conditions_hash=nil)
      if conditions_hash && !conditions_hash.empty?
        conditions_hash = BlocRecord::Utility.convert_keys(conditions_hash)
        conditions = conditions_hash.map {|key, value| "#{key} = #{BlocRecord::Utility.sql_strings(value)}"}.join(' and ')

        connection.execute <<-SQL
          DELETE FROM #{table}
          WHERE #{conditions};
        SQL
      else
        connection.execute <<-SQL
          DELETE FROM #{table}
        SQL
      end

      true
    end
  end # Ends ClassMethods
end # Ends Persistence
