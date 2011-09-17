require 'bundler'
require 'rspec'
require 'rspec/core/rake_task'
require 'rake'
require 'rake/extensiontask'

Bundler::GemHelper.install_tasks
RSpec::Core::RakeTask.new(:spec)
Rake::ExtensionTask.new("cdict")
Rake::ExtensionTask.new("logic")
