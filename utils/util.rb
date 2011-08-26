#!/usr/bin/env ruby
    def fill!
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
