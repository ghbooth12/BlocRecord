# Add a custom instance method.

# If the condition is like:
# Article.joins(comments: :guest).where('comment.body IS NULL')

# Article.joins(comments: :guest) is an Array.
# To be able to chain ".joins" and ".where",
# I need to create an instance method inside the Array class.

class Array
  def where(str)
    # .joins returns an array and its first element is a SQL query
    # so that I can combine that SQL query with a new query(= str).

    # self: ["INNER JOIN entry ON entry.address_book_id = address_book.id INNER JOIN comment ON comment.entry_id = entry.id", #<AddressBook:0x007fbcd5026338 @id=1, @name="My Address Book">, #<AddressBook:0x007fbcd50253e8 @id=1, @name="My Address Book">, #<AddressBook:0x007fbcd5024600 @id=1, @name="My Address Book">, #<AddressBook:0x007fbcd49a7e08 @id=1, @name="My Address Book">]

    # self[0] is the JOIN SQL query.
    # self[1].class is AddressBook.
    self[1].class.inner_where(self[0], str)
  end
end
