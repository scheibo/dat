require 'set'
require 'pp'

$dict = {}

class Word
  attr_accessor :definition
  alias defn definition
  alias defn= definition=

  def initialize(word, defn)
    @word = word
    @definition = defn
    @relatives = Set.new
  end

  def add_relative(word)
    @relatives.add(word) if word != @word
  end

  def relatives
    @relatives.clone
  end
end

def make_word(word, defn)
  if !$dict[word]
    $dict[word] = Word.new(word, defn)
  else
    $dict[word].definition = defn
  end
end

def relatives(w1, w2, defn)
  make_word(w1, defn)
  make_word(w2, defn)
  $dict[w1].add_relative(w2)
  $dict[w2].add_relative(w1)
end

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
    us = nil
    suffixes.each do |suf|
      us = suf if word.end_with?(suf)
    end

    # determine the root word - if we are a suffix then we need to calculate it
    if us
      root = word[0,word.size-us.size]
    else
      root = word
    end

    # add relatives to the hash entry
    suffixes.each do |suf|
      w = "#{root}#{suf}"
      relatives(w, word, defn)
      relatives(w, root, defn)
      relatives(root, word, defn)
    end

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

  matches.each do |m1|
    matches.each do |m2|
      relatives(m1, m2, defn)
    end
    relatives(m1, word, defn)
  end

end
dump = Marshal.dump $dict
File.open('dumped.dict', 'w').write dump

dict = Marshal.load(File.open('dict.dat').read)

pp dict

