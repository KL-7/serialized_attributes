require 'rubygems'
require 'bundler/setup'
require 'rake'

require 'jeweler'
Jeweler::Tasks.new do |gem|
  gem.name        = "serialized_attributes"
  gem.homepage    = "http://github.com/emmapersky/serialized_attributes"
  gem.license     = "MIT"
  gem.summary     = %Q{Simple serialization of row level attributes}
  gem.description = %Q{Serialize model attributes to a single database column instead}
  gem.email       = "emma.persky@gmail.com"
  gem.authors     = ["Emma Persky"]

  # all dependencies are specified in the Gemfile

  gem.files = %w[
    Gemfile
    Gemfile.lock
    lib/serialized_attributes.rb
    lib/serialized_attributes/serialized_attributes.rb
    LICENSE.txt
    Rakefile
    README.md
    test/simple_test.rb
    VERSION
  ]

  gem.require_paths = ["lib"]
end
Jeweler::RubygemsDotOrgTasks.new

require 'rake/testtask'
Rake::TestTask.new(:test) do |test|
  test.libs << 'lib'
  test.pattern = 'test/**/*.rb'
  test.verbose = true
end

task :default => :test

if RUBY_VERSION < '1.9.0'
  require 'rcov/rcovtask'
  Rcov::RcovTask.new('test:cov') do |test|
    test.libs << 'lib'
    test.pattern   = 'test/**/*.rb'
    test.verbose   = true
    test.rcov_opts = ['-T', '--sort coverage', '--exclude gems/,spec/']
  end
end