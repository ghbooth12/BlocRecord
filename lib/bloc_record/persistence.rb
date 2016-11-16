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
      return true
    end

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
  end # Ends ClassMethods
end # Ends Persistence
