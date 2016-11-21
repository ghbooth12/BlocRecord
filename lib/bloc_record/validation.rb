module Validation
  extend self

  def validate(schema_hash, attrs)
    keys = schema_hash.keys
    keys.delete("id")  # Note: If schema_hash.delete("id"), the schema's id will be deleted too!
    for key in keys
      type = schema_hash[key]
      val = attrs[key]

      if type.include?("INTEGER")
        result = val.kind_of?(Integer) && val > 0
      elsif type.include?("TEXT") || type.include?("VARCHAR")
        result = val.kind_of?(String)
      end

      unless result
        return false
      end
    end # Ends for loop

    return true
  end # Ends validate()
end # Ends Validation
