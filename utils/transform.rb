#!/usr/bin/env ruby
$: << File.expand_path('../../lib/dat', __FILE__)
require 'word'
include Dat

$dict = {}

ANGLE_BRACKET_REGEX = /<([a-z]+)=([a-z]+)>/
TYPE_IN_BRACKET_REGEX = /\[([a-z]+).*\]/
CAPS_REGEX = /\s([A-Z]{3,})/
SUFFIX_REGEX = /\s-([A-Z]+)/

BASIC_SUFFIXES = %w{S ED ING ES}

def transform(infile, outfile, simple=true)
  infile.each_line do |line|
    space = line.index " "

    if space
      word, defn = line[0...space], line[space+1..line.size].chomp
    else
      word = line.chomp
      $dict[word] = Word.new(word)
      next
    end

    check_angle_bracket word, defn
    check_for_type_in_bracket word, defn
    check_for_caps word, defn
    check_for_suffixes word, defn, simple

    set_definitions word, defn
  end

  $dict.each { |k,v| outfile.puts v.to_dict_entry }
end

def set_definitions(word, defn)
  # remove expressions we don't want in the final expression
  defn = defn.gsub(/<.*>/, "").gsub(/\[.*\]/, "").gsub("  ", " ")

  g(word).definition = defn if defn.size > g(word).definition.size
  g(word).relatives.each do |r|
    r.definition = defn if defn.size > r.definition.size
  end
end

def g(word)
  $dict[word] ||= Word.new(word)
end

def check_angle_bracket(word, defn)
  if defn =~ ANGLE_BRACKET_REGEX
    relative = $~[1].upcase
    type = $~[2]
    Word.relatives g(word), g(relative)
    g(word).type = type
  end
end

def check_for_type_in_bracket(word, defn)
  if defn =~ TYPE_IN_BRACKET_REGEX
    g(word).type = $~[1]
  end
end

def check_for_caps(word, defn)
  dfn = defn
  matches = []
  while (idx = (dfn =~ CAPS_REGEX))
    matches << $~[1]
    dfn = dfn[idx+$~.to_s.size..dfn.size]
  end
  Word.relatives(*(matches.map {|w| g(w)}), g(word))
end

def check_for_suffixes(word, defn, simple)
  dfn = defn
  suffixes = []
  while (idx = (dfn =~ SUFFIX_REGEX))
    suffixes << $~[1]
    dfn = dfn[idx+$~.to_s.size..dfn.size]
  end

  if simple
    words = suffixes.map { |suf| g("#{word}#{suf}") }
    Word.relatives(*words, g(word))
  else
    words = []
    suffixes.each do |suf|
      if BASIC_SUFFIXES.include?(suf)
        words << g("#{word}#{suf}")
      else
        idx = word.rindex(suf[0])
        if idx
          words << g("#{word[0...idx]}#{suf}")
        else
          words << g("#{word}#{suf}")
        end
      end
    end
    Word.relatives(*words, g(word))
  end
end

# If we keep the same dictionary between all the rounds and just read more
# words, we hopefully get the best of all files
transform File.open('../data/orig/csw.txt'), File.open('/dev/null', 'w')
transform File.open('../data/orig/ospd4-lwl.txt'), File.open('/dev/null', 'w'), false
transform File.open('../data/orig/oswi.txt'), File.open('/dev/null', 'w')
transform File.open('../data/orig/owl-lwl.txt'), File.open('/dev/null', 'w'), false
transform File.open('../data/orig/owl2-lwl.txt'), File.open('../data/all.txt', 'w'), false
