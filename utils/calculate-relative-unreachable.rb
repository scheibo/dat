#!/usr/bin/env ruby
$: << File.expand_path('../../lib', __FILE__)
require 'dat'
include Dat

dict = Dict.new

dict.each do |k,v|
  results = Logic.perturb(k, dict)
  if v.relatives.union(results).difference(v.relatives).empty?
    dict.delete(v)
  end
end

puts dict
