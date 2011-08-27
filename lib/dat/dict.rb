$:.unshift(File.expand_path('../../dat', __FILE__)) unless $:.include?(File.expand_path('../../dat', __FILE__))
require 'word'

module Dat
  class Dict
    def initialize(file='dict', bogus='bogus')
      # The internal hash which maps string words to Dat::Word objects
      @dict = {}
      import file
      remove bogus
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

    def import(file)
      File.open(File.expand_path("../../../data/#{file}", __FILE__)) do |f|
        f.each_line do |line|
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
      end
    end

    def remove(bogus)
      File.open(File.expand_path("../../../data/#{bogus}", __FILE__)) do |f|
        f.each_line do |line|
          command, rest = line[0], line[2..-1].chomp
          case command
          when 'd' then delete get(rest)
          when 'i' then get(rest).isolate!
          when 'r' then Word.relatives rest.split(" ").map { |w| get(w) }
          end
        end
      end
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
