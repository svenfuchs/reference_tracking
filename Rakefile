require 'rake'
require 'rake/testtask'

Rake::TestTask.new do |t|
  t.libs << 'lib'
  t.pattern = 'test/all.rb'
  t.verbose = false
end

task :default => :test
