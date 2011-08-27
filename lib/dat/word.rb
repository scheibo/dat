require 'set'

module Dat
  class Word
    attr_reader :word
    attr_accessor :definition, :type
    alias defn definition
    alias defn= definition=

    def initialize(word, defn=" ")
      @word = word
      @definition = defn
      @relatives = Set.new
    end

    def add_relative(word)
      @relatives.add word if word.word != @word and word.word[0] == @word[0]
    end

    def relatives
      @relatives #.clone
    end

    def to_s
      @word
    end

    def to_dict_entry
      str = @word.clone
      str << (@type ? " (" << @type << ") " : " ")
      str << @definition << " " unless @definition.strip.empty?
      str << "[#{@relatives.to_a.join(" ")}]"
    end

    # Helper to declare that two words come from the same root
    def self.relatives(*words)
      # make a set of all the relatives
      relatives = Set.new
      words.each do |word|
        word.relatives.each { |rs| relatives.add(rs) }
        relatives.add(word)
      end

      # update words to include the full list of relatives
      words.each do |word|
        relatives.each { |r| word.add_relative(r) }
      end
    end
  end
end
