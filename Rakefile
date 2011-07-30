require 'rake/testtask'

task :default => :test

task :test => ['test:units', 'test:integration']

Rake::TestTask.new('test:units') do |t|
  t.libs << "test"
  t.test_files = FileList['test/unit/*_test.rb']
  t.verbose = true
end

Rake::TestTask.new('test:integration') do |t|
  t.libs << "test"
  t.test_files = FileList['test/integration/*_test.rb']
  t.verbose = true
end
