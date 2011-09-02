module Dat
  class Logic
    def self.perturb(word, dict, opt={})
      min_size = opt[:min_size]
      opt.default = true
      size = word.size
      result = []
      if opt[:add]
        (0..size).each do |i|
          try_letters(word[0,i], word[i,size], word,  dict, result)
        end
      end

      if opt[:replace]
        (0...size).each do |i|
          try_letters(word[0,i], word[i+1,size], word, dict, result)
        end
      end

      if opt[:delete]
        (0...size).each do |i|
          w = "#{word[0,i]}#{word[i+1,size]}".upcase
          if dict[w] && (!min_size || w.size >= min_size)
            result << dict[w]
          end
        end
      end

      result
    end

    private

    def self.try_letters(start, finish, word, dict, result)
      ('A'..'Z').each do |c|
        w = "#{start}#{c}#{finish}".upcase
        if dict[w] && w != word.upcase
          result << dict[w]
        end
      end
      result
    end
  end
end
