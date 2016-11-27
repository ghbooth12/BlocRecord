# e.g. Person.where(boat: true).update_all(boat: false)
module BlocRecord
  # Create update_all method in the custom Collection class.
  class Collection < Array
    def update_all(updates)
      ids = self.map(&:id)
      # update is a class method.
      self.any? ? self.first.class.update(ids, updates) : false
    end

    # Person.all.group(:name)
    # Person.all.group(:name, :age)
    def group(*args)
      ids = self.map(&:id) # self.map {|obj| obj.id}
      self.any? ? self.first.class.group_by_ids(ids, args) : false
    end

    # Entry.select(:name).distinct
    def distinct
      ids = self.map(&:id)  # self.map {|obj| obj.id}
      self.any? ? self.first.class.distinct_with_ids(ids) : false
    end
  end
end
