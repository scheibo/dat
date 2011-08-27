$:.unshift(File.expand_path('../../dat', __FILE__)) unless $:.include?(File.expand_path('../../dat', __FILE__))
require 'word'

module Dat
  class Dict
    def initialize
      # The internal hash which maps string words to Dat::Word objects
      @dict = {}
      fill!
      clean!
    end

    def [](word)
      @dict[word.upcase]
    end

    def each
      @dict.each do |k,v|
        yield k,v
      end
    end

    def delete(word)
      word.relatives.each do |r|
        r.relatives.delete word
      end
      @dict.delete word.word
    end

    def to_s
      result = ""
      @dict.each { |k,v| result << v.to_dict_entry << "\n" }
      result
    end

    private

    def fill!
      File.open(File.expand_path('../../../data/dict', __FILE__)) do |f|
        f.each_line do |line|
          line.chomp!
          #space, paren, brace = line.index(" "), line.index(/(\(.*\))/), line.index("[")
# returns nil if no paren
#word, defn, rels = line[0...space], line[paren,$~[1].size], line[paren+$~[1].size...brace].strip, line[brace+1...line.size-1].split(" ")
          space, brace = line.index(" "), line.index("[")
          word, defn, rels = line[0...space], line[space...brace].strip, line[brace+1...line.size-1].split(" ")
          Word.relatives(*(rels.map {|r| get(r)}), get(word))
        end
      end
    end

    def clean!
      File.open(File.expand_path('../../../data/bogus', __FILE__)) do |f|
        f.each_line do |line|
          delete get(line.chomp)
        end
      end
    end

    def get(word)
      @dict[word] ||= Word.new(word)
    end
  end
end
