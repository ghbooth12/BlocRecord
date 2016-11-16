# Users of our ORM will subclass Base When creating their model objects.

require 'bloc_record/utility'
require 'bloc_record/schema'
require 'bloc_record/persistence'
require 'bloc_record/selection'
require 'bloc_record/connection'

module BlocRecord
  class Base
    # encapsulation into separate modules makes the code more readable and more easily understood
    include Persistence   # include: add instance methods to a class
    extend Selection  # extend: add class methods to a class
    extend Schema
    extend Connection

    def initialize(options={})
      options = BlocRecord::Utility.convert_keys(options)

      # Iterate each column
      # This method uses self.class to get the class's dynamic, runtime type,
      # and calls columns on that type.
      # e.g. if BookAuthor inherits from Base,
      # self.class would be BookAuthor.class.
      self.class.columns.each do |col|
        # Use Object::send to send the column name to attr_accessor.
        # This creates an instance variable getter and setter for each column.
        self.class.send(:attr_accessor, col)

        # Use Object::instance_variable_set to set the instance variable to the value corresponding to that key in the options hash.
        self.instance_variable_set("@#{col}", options[col])
      end

      # Dynamically typed languages (Ruby, JS, PHP, Object-C):
      # => We can create instance variables at runtime
      # Statically typed languages (C, Java, Swift):
      # => We must specify the types of all variables up front
    end
  end
end
