# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "dat/version"

Gem::Specification.new do |s|
  s.name        = "dat"
  s.version     = Dat::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Kirk Scheibelhut"]
  s.email       = ["kjs@scheibo.com"]
  s.homepage    = "https://github.com/scheibo/dat"
  s.summary     = "Word game which deals with altering words adding, deleting or replacing letters."
  s.description = s.summary

  s.rubyforge_project = "dat"

  s.add_development_dependency "rake"
  s.add_development_dependency "rake-compiler"
  s.add_development_dependency "bundler", "~> 1.0.0"

  s.extensions = ["ext/dat/extconf.rb"]

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.default_executable = 'dat'
  s.require_paths = ["lib"]
end
