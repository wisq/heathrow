require 'rake/testtask'

task :default => :test

task :test => ['test:units']

Rake::TestTask.new('test:units') do |t|
  t.libs << "test"
  t.test_files = FileList['test/unit/*_test.rb']
  t.verbose = true
end
