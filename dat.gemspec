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
  s.summary     = "Dat app"
  s.description = s.summary

  s.rubyforge_project = "dat"

  #s.add_dependency "algorithms"

  # s.rdoc_options = ["--line-numbers", "--inline-source", "--title", "Dat", "--main", "Dat"] # from rtomayko
  # s.extra_rdoc_files = %w[README.md LICENSE]

  s.add_development_dependency "rake"
  s.add_development_dependency "bundler", "~> 1.0.0"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.default_executable = 'dat'
  s.require_paths = ["lib"]
end
