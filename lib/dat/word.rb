require 'set'

module Dat
  class Word
    attr_reader :word, :relatives
    attr_accessor :definition, :type
    alias get word

    def initialize(word, defn="")
      @word = word.upcase
      @definition = defn
      @relatives = Set.new
    end

    def add_relative(word)
      @relatives.add word if word.get != @word
    end
    alias << add_relative

    def to_s
      @word
    end

    def to_dict_entry
      str = @word.clone
      str << (@type ? " (" << @type << ") " : " ")
      str << @definition.strip << " " unless @definition.strip.empty?
      str << "[#{@relatives.to_a.join(" ")}]"
    end

    # Helper to declare that words come from the same root
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
