$:.unshift(File.expand_path('../../dat', __FILE__)) unless $:.include?(File.expand_path('../../dat', __FILE__))
require 'word'

module Dat
  class Dict
    def initialize
      # The internal hash which maps string words to Dat::Word objects
      @dict = {}
      fill!
    end

    def [](word)
      @dict[word]
    end

    def each
      @dict.each do |k,v|
        yield k,v
      end
    end

    def delete(word)
      word.relatives.each do |r|
        @dict[r].relatives.delete word.word
      end
      @dict.delete word.word
    end

    def to_s
      result = ""
      @dict.each { |k,v| results << v.to_s }
      result
    end

    private

    def fill!
      File.open(File.expand_path('../../../data/dict', __FILE__)) do |f|
        f.each_line do |line|
          space, brace = line.index " ", line.index "["
          word, defn, rels = line[0...space], line[space...brace], line[brace+1...line.size-1].chomp.split " "
          Word.relatives(*(rels.map {|r| get(r, defn)}), get(word, defn))
        end
      end
    end

    def get(word, defn)
      @dict[word] ||= Word.new(word, defn)
    end

  end
end
