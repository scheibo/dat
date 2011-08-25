$:.unshift(File.expand_path('../../dat', __FILE__)) unless $:.include?(File.expand_path('../../dat', __FILE__))
require 'word'

module Dat
  class Dict
    def initialize
      # The internal hash which maps string words to Dat::Word objects
      @dict = {}
      fill
    end

    def [](word)
      @dict[word]
    end

    def to_s
      # TODO sloppy, builds up a lot of memory - better way?
      result = ""
      @dict.each do |k,v|
        result << "#{k} #{v.defn}\n"
      end
      result
    end

    private

    def fill
      File.open(File.expand_path('../../../data/dict', __FILE__)) do |f|
        f.each_line do |line|
          space = line.index " "
          if space
            word, defn = line[0...space], line[space+1..line.size].chomp
          else
            word, defn = line.chomp, ""
          end

          suffix word, defn
          caps word, defn
        end
      end
    end

    def suffix(word, defn)
      if defn =~ /\[\w*((\s(-[A-Z]+),?)*)\]/
        suffixes = $~[1].split(",").map(&:strip).map {|w| w.delete "-" }

        us = nil
        suffixes.each do |suf|
          us = suf if word.end_with?(suf)
        end

        root = us ? word[0,word.size-us.size] : word

        suffixes.each do |suf|
          Word.relatives get("#{root}#{suf}", defn), get(word, defn), get(root, defn)
        end
      end
    end

    def caps(word, defn)
      dfn = defn
      matches = []
      while (idx= dfn  =~ /[^\[]\s([A-Z]{2,})/)
        match = $~[1]
        matches << match
        dfn = dfn[idx+$~.to_s.size..dfn.size]
      end

      Word.relatives(*(matches.map {|w| get(w, defn)}), get(word, defn))
    end

    def get(word, defn)
      if !@dict[word]
        @dict[word] = Word.new(word, defn)
      else
        @dict[word].definition = defn if defn.size > @dict[word].definition.size
      end
      @dict[word]
    end

  end
end
