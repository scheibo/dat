require 'set'

module Dat
  class Word
    attr_reader :word
    attr_accessor :definition, :type
    alias defn definition
    alias defn= definition=

    def initialize(word, defn)
      @word = word
      @definition = defn
      @relatives = Set.new
    end

    def add_relative(word)
      @relatives.add word if word.word != @word.word
    end

    def relatives
      @relatives #.clone
    end

    def to_s
      str = @word.clone
      str << "(#{@type})" if @type
      str << @definition
      str << "[#{@relatives.join(" ")}]"
    end

    # Helper to declare that two words come from the same root
    def self.relatives(*words)
      words.permutation(2).each do |pair|
        pair[0].add_relative(pair[1].word)
        pair[1].add_relative(pair[0].word)
      end
    end
  end
end
