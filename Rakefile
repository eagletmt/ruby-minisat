require "bundler/gem_tasks"

task :default => :spec

require 'rspec/core/rake_task'
RSpec::Core::RakeTask.new :spec
task :spec => :compile
task :compile => 'ext/minisat/Solver.cc'
file 'ext/minisat/Solver.cc' => 'vendor/minisat/core/Solver.cc' do |t|
  ln_s Pathname.new(t.prerequisites.first).realpath, t.name, :force => true
end

require 'rake/extensiontask'
Rake::ExtensionTask.new :minisat

require 'yard'
require 'yard/rake/yardoc_task'
YARD::Rake::YardocTask.new do |t|
  t.files = FileList['README.md', 'ext/**/*.cc', 'lib'].to_a
end
