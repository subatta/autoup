require 'rake/testtask'

Rake::TestTask.new do |t|
  t.warning = true
  t.verbose = true
  t.test_files = FileList['spec/*_spec.rb']
end

task :default => [:test]
