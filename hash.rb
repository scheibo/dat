#!/usr/bin/env ruby

require 'set'

dict = {}

ARGF.each_line do |line|

  space = line.index " "
  # seperate into word and definition
  if space
    word, defn = line[0...space], line[space+1..line.size].chomp
  else
    word, defn = line.chomp, ""
  end

  # do the suffix matches
  if defn =~ /\[\w*((\s(-[A-Z]+),?)*)\]/
    suffixes = $~[1].split(",").map(&:strip).map {|w| w.delete "-" }

    # determine if we are a suffix, kind of rough but good enough
    suffixes.each do |suf|
      us ||= word.end_with?(suf)
    end

    # determine the root word - if we are a suffix then we need to calculate it
    if us
      root = word[0,word.size-suf.size]
    else
      root = word
    end

    # create the hash entry
    dict[word] = Word.new(defn)

    # add relatives to the hash entry
    suffixes.each do |suf|
      dict[word].add_relative("#{root}#{suf}")
    end

    if !dict[root]
      dict[root] = Word.new(defn)
    end

    dict[root].add_relative(word)

    next # anything with a suffix match doesn't have a cap match?
  end

  # get all cap words out of the line and print them with the defn
  dfn = defn
  matches = []
  while (idx= dfn  =~ /[^\[]\s([A-Z]{2,})/)
    match = $~[1]
    matches << match
    dfn = dfn[idx+$~.to_s.size..dfn.size]
  end

  # if any of the cap words match then we are a cap word ourselves
  matches.each do |w|
    us ||= w == word
  end

  if !us
    root =

end

class Word
  attr_reader definition, root

  def initialize(defn)
    @definition = defn
    @relatives = Set.new
  end

  def add_relative(word)
    @relatives.add(word)
  end

  def relatives
    @relatives.clone
  end

  alias defn definition
end
