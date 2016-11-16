Gem::Specification.new do |s|
  s.name          = 'bloc_record'
  s.version       = '0.0.0'
  s.date          = '2016-11-15'
  s.summary       = 'BlocRecord ORM'
  s.description   = 'An ActiveRecord-esque ORM adaptor'
  s.authors       = ['Gahee Heo']
  s.email         = 'ghbooth12@gmail.com'
  s.files         = `git ls-files`.split($/)
  s.require_paths = ["lib"]
  s.homepage      = 'http://rubygems.org/gem/bloc_record'
  s.license       = 'MIT'
  s.add_runtime_dependency 'sqlite3', '~> 1.3'
end


# files is an array of files included in the gem. You could list them individually (like  s.files = ['lib/bloc_record.rb']) but we're using git ls-files, which prints a list of files in your Git repository.

# We added a sqlite3 dependency using add_runtime_dependency. This instructs bundle to install sqlite3-ruby, which provides a programmatic Ruby interface to SQLite. (It lets you write Ruby code instead of using the command line.)

# The string '~> 1.3' indicates we want the latest possible version in the in the version 1.3 minor range. That is, if we have version 1.3.6 and version 1.3.7 comes out, we want to use that, but we don't want version 1.4. This is called semantic versioning.
