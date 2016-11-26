# To encapsulate the connection-related code in  lib/bloc_record/

require 'sqlite3' # Import the SQLite library

module Connection
  extend self
  def connection
    # puts "connection 1"
    # Pass the database filename to the library which will open the database
    # A new Database object will be initialized from the file the first time connection is called.
    # We'll interact with this object to read and write data.
    @connection ||= SQLite3::Database.new(BlocRecord.database_filename)
  end
end
