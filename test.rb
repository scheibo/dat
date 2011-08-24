#!/usr/bin/env ruby
require 'set'

class Word
  attr_accessor :definition

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

  alias defn definition
end

h = Word.new('hello', 'definition of the word')

h.add_relative('happy')
h.add_relative('sappy')
h.add_relative('happy')
h.add_relative('hello')

p h.relatives
p h.defn
p h.definition

h.definition = 'new defn'
p h.defn
p h.definition
