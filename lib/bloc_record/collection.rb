# e.g. Person.where(boat: true).update_all(boat: false)
module BlocRecord
  # Create update_all method in the custom Collection class.
  class Collection < Array
    def update_all(updates)
      ids = self.map(&:id)
      # update is a class method.
      self.any? ? self.first.class.update(ids, updates) : false
    end

    # Person.where(first_name: 'John').where(last_name: 'Smith')
    def where(attrs)
      output = []
      for obj in self
        for key in attrs.keys
          output += self.first.class.where("id" => obj.id, key => attrs[key])
        end
      end
      output
    end

    # Person.where(first_name: 'John').take
    def take(num=1)
      self[0..num-1]
    end
  end
end
