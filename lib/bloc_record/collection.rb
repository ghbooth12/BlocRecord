# e.g. Person.where(boat: true).update_all(boat: false)
module BlocRecord
  # Create update_all method in the custom Collection class.
  class Collection < Array
    def update_all(updates)
      ids = self.map(&:id)
      # update is a class method.
      self.any? ? self.first.class.update(ids, updates) : false
    end
  end
end
