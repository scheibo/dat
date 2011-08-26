#!/usr/bin/env ruby

dictionary = {}
ARGF.each_line do |line|
  space = line.index " "
  if space
    word, defn = line[0...space], line[space+1..line.size].chomp
  else
    word, defn = line.chomp, ""
  end
  dictionary[word.downcase] = defn
end

File.open('relative').each_line do |line|
  word = line.chomp
  dictionary.delete(word)
end

dictionary.each do |k, v|
  puts "#{k.upcase} #{v}"
end
