#!/usr/bin/env ruby

# we want to match lines with a [ ] in them, saving whats inside.
# we either get suffixes (with -XXX) or all caps words which also go with the word
# we want to take each of these (suffix of caps word) and put it on its own line with
# the same orig def - notice running this twice would not work since we still leave in


ARGF.each_line do |line|

  space = line.index " "
  # seperate into word and definition
  if ! space.nil?
    print line # echo the line right back
    word, defn = line[0...space], line[space+1..line.size].chomp
  else
    # add a marker so we know it will come first in sorted order
    word, defn = line.chomp, "!!!!!"
    puts "#{word} #{defn}"
  end

  # do the suffix matches
  if defn =~ /\[\w*((\s(-[A-Z]+),?)*)\]/
    suffixes = $~[1].split(",").map(&:strip).map {|w| w.delete "-" }
    suffixes.each do |suf|
      puts "#{word+suf} #{defn}"
    end
    next # anything with a suffix match doesn't have a cap match?
  end

  # get all cap words out of the line and print them with the defn
  dfn = defn
  while (idx= dfn  =~ /[^\[]\s([A-Z]{2,})/)
    match = $~[1]
    puts "#{match} #{defn}"
    dfn = dfn[idx+$~.to_s.size..dfn.size]
  end

end
