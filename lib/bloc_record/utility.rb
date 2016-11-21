# This contains some general, reusable utility functions for transforming data.
module BlocRecord
  module Utility
    # self refers to the Utility. So underscore will be a class method instead of an instance method. We can run code like BlocRecord::Utility.underscore('TextLikeThis').
    extend self

    # This converts TextLikeThis into text_like_this.
    # Because Ruby class names are camel case, while SQL table names are snake case.
    def underscore(camel_cased_word)
      string = camel_cased_word.gsub(/::/, '/')

      # Insert an underscore between any all-caps class prefixes(like acronyms) and other words.
      string.gsub!(/([A-Z]+)([A-Z][a-z])/, '\1_\2')

      # Insert an underscore between any camelcased words
      string.gsub!(/([a-z\d])([A-Z])/,'\1_\2')

      string.tr!("-", "_")
      string.downcase
    end

    # This method converts value to an appropriate SQL string.
    # Note: "30" will be retuned. But combining other string and "30" is "age = 30".
    # Note: "null" will be returned. But combining other string and "null" is "phone = null"
    def sql_strings(value)
      case value
      when String     # "name = #{sql_strings("John")}"
        "'#{value}'"  # "name = 'John'"
      when Numeric    # "age = #{sql_strings(30)}"
        value.to_s    # "age = 30"
      else            # "phone = #{sql_strings(true)}"
        "null"        # "phone = null"
      end
    end

    # This method converts symbol keys to string keys.
    def convert_keys(options)
      options.keys.each {|k| options[k.to_s] = options.delete(k) if k.kind_of?(Symbol)}
      options
    end

    # This method converts an object's instance varialbe to a Hash.
    # This method is the inverse of Base::initialize.
    # Instea of assigning instance variables from a hash,
    # it iterates an object's instance_variables to build a hash representation.
    def instance_variables_to_hash(obj)
      Hash[obj.instance_variables.map {|var| ["#{var.to_s.delete('@')}", obj.instance_variable_get(var.to_s)]}]
    end

    def reload_obj(dirty_obj)
      # Find dirty_obj's saved representation.
      persisted_obj = dirty_obj.class.find_one(dirty_obj.id)
      dirty_obj.instance_variables.each do |instance_variable|
        # Overwrite the instance variable values with the stored values from the database.
        # This will discard any unsaved changes to the given object.
        dirty_obj.instance_variable_set(instance_variable, persisted_obj.instance_variable_get(instance_variable))
      end
    end
  end # Ends Utility
end # Ends BlocRecord
