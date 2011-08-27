#!/usr/bin/env ruby
$: << File.expand_path('../../lib', __FILE__)
require 'dat'
include Dat
require 'set'

d = Dict.new
puts d
=begin
hm = Set.new
nu = Set.new
File.open('hm').each_line do |line|
  idx =line.index " "
  hm.add(line[0...idx])
end

File.open('nu').each_line do |line|
  idx =line.index " "
  nu.add(line[0...idx])
end

p nu.difference(hm)
=end
