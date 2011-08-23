#!/usr/bin/env ruby

dict = {}
ARGF.each_line do |line|
  space = line.index " "
  word, defn = line[0...space], line[space+1..line.size].chomp
  if defn == "!!!!!" and dict[word].nil?
    dict[word] = ""
  else
    if !dict[word]
      dict[word] = defn
    else
      if (dict[word].size < defn.size)
        # always take the longer definition
        dict[word] = defn
      end
    end
  end
end

dict.each do |k,v|
  puts "#{k} #{v}"
end
