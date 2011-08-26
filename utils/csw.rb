#!/usr/bin/env ruby
$: << File.expand_path('../../lib/dat', __FILE__)
require 'word'
include Dat

$dict = {}

def transform(file)
  file.each_line do |line|
    line.chomp!
    space = line.index " "

    if space
      word, defn = line[0...space], line[space+1..line.size]
    else
      $dict[word] = Word.new(word, " ")
      next
    end

    check_angle_bracket word, defn
    check_for_type_in_bracket word, defn
    check_for_caps word, defn
    check_for_suffixes word, defn
  end

  $dict.each { |k,v| puts v }
end

def g(word, defn)
  if !$dict[word]
    $dict[word] = Word.new(word, defn)
  else
    $dict[word].definition = defn if defn.size > $dict[word].definition
  end
end

def check_angle_bracket(word, defn)
  if defn =~ /<([a-z]+)=([a-z]+)>/
    relative = $~[1]
    type = $~[2]
    Word.relatives g(word, defn), g(relative, defn)
    word.type = type
  end
end

def check_for_type_in_bracket(word, defn)
  if defn =~ /\[([a-z]+).*\]/
    word.type = $~[1]
  end
end

def check_for_caps(word, defn)
  dfn = defn
  matches = []
  while (idx = (dfn =~ /\s([A-Z]+)/))
    matches << $~[1]
    dfn = dfn[idx+$~.to_s.size..dfn.size]
  end
  Word.relatives(*(matches.map {|w| g(w, defn)}), g(word, defn))
end

=begin
def check_for_suffixes(word, defn)
  if defn =~ /\[\w*((\s(-[A-Z]+),?)*)\]/
    suffixes = $~[1].split(",").map(&:strip).map {|w| w.delete "-" }

    us = nil
    suffixes.each do |suf|
      us = suf if word.end_with?(suf)
    end

    root = us ? word[0,word.size-us.size] : word

    suffixes.each do |suf|
      Word.relatives get("#{root}#{suf}", defn), get(word, defn), get(root, defn)
    end
  end
end
=end
