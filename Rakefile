require "rubygems"
require "rake/testtask"

task :default => :test

Rake::TestTask.new do |t|
  t.test_files = FileList['test/*_test.rb']
  t.verbose = true
end

task :clean do
  %x{rm -rf *.gem doc}
end

task :gem do
  %x{gem build friendly_id.gemspec}
end

task :yard do
  %x{yard doc}
end

namespace :test do
  # Test lots of versions and databases
  task :all do
    ["postgres", "mysql", "sqlite3"].map do |db|
      ENV["DB"] = db
      puts %x{rake test}
    end
  end
end

namespace :db do

  desc "Set up the database schema"
  task :up do
    require File.expand_path("../test/helper", __FILE__)
    FriendlyId::Test::Schema.up
  end

  desc "Destroy the database schema"
  task :down do
    require File.expand_path("../test/helper", __FILE__)
    FriendlyId::Test::Schema.down
  end

end

task :doc => :yard
