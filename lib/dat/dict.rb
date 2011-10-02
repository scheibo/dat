$:.unshift(File.expand_path('../../dat', __FILE__)) unless $:.include?(File.expand_path('../../dat', __FILE__))
require 'word'

module Dat
  class Dict
    def initialize(opt={})
      @dict = {} # The internal hash which maps string words to Dat::Word objects
      file = opt[:file] || File.open(File.expand_path("../../../data/dict", __FILE__))
      bogus = opt[:bogus] || File.open(File.expand_path("../../../data/bogus", __FILE__))

      import file
      remove bogus
    end

    def [](word)
      @dict[word]
    end

    def each(&block)
      @dict.each(&block)
    end

    def delete(word)
      word.relatives.each do |r|
        r.relatives.delete(word)
      end
      @dict.delete(word.get)
    end

    def to_s
      result = ""
      @dict.each { |k,v| result << v.to_dict_entry << "\n" }
      result
    end

    private

    def import(file)
      file.each_line do |line|
        line.chomp!
        space, paren, brace = line.index(" "), line.index(/\(([a-z]+)\)/), line.index("[")
        if paren
          word, type, defn, rels = line[0...space], line[paren+1,$~[1].size], line[paren+$~[1].size+2...brace].strip, line[brace+1...line.size-1].split(" ")
          get(word).type = type
        else
          word, defn, rels = line[0...space], line[space...brace].strip, line[brace+1...line.size-1].split(" ")
        end
        Word.relatives(*(rels.map {|r| get(r)}), get(word, defn))
      end
      file.close
    end

    def remove(file)
      file.each_line do |line|
        command, rest = line[0], line[2..-1].chomp
        case command
        when 'd' then delete(get(rest))
        when 'i' then get(rest).isolate!
        when 'r' then Word.relatives(rest.split(" ").map { |w| @dict[w] }.compact)
        end
      end
      file.close
    end

    def get(word, defn=nil)
      @dict[word] ||= Word.new(word)
      if defn
        @dict[word].definition = defn
      end
      @dict[word]
    end
  end
end
