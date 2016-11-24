# To create a record
# This module must work directly with the database and understand the schema.

require 'sqlite3'
require 'bloc_record/schema'

module Persistence
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
      attrs.delete("id")
      vals = attributes.map {|key| BlocRecord::Utility.sql_strings(attrs[key])}

      connection.execute <<-SQL
        INSERT INTO #{table} (#{attributes.join(",")})
        VALUES (#{vals.join(",")});
      SQL

      # This creates 'data', a hash of attributes and values.
      # data = {"name"=>"Jar-Jar Binks", "rating"=>1}
      # SELECT last_insert_rowid(); returns the ROW ID of the last row insert.
      # new calls the create method in the base class and returns the result.
      data = Hash[attributes.zip(attrs.values)]
      data["id"] = connection.execute("SELECT last_insert_rowid();")[0][0]
      new(data)
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
  end # Ends ClassMethods
end # Ends Persistence
