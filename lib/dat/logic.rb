module Dat
  class Logic
    def self.perturb(word, dict, opt={})
      word.upcase!
      min_size = opt[:min_size]
      opt.default = true

      #c_pertub(word, dict, min_size) if opt[:add] && opt[:replace] && opt[:delete]

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

    def self.levenshtein(s, t)
      m, n = s.size, t.size
      # for all i and j, d[i,j] will hold the Levenshtein distance between
      # the first i characters of s and the first j characters of t;
      # note that d has (m+1)x(n+1) values
      d = Array.new(m+1) { Array.new(n+1) }

      (0..m).each do |i|
        d[i][0] = i # the distance of any first string to an empty second string
        (0..n).each do |j|
          d[0][j] = j # the distance of any second string to an empty first string
        end
      end

      (1..n).each do |j|
        (1..m).each do |i|
          if s[i-1] == t[j-1]
            d[i][j] = d[i-1][j-1]
          else
            #              delete         insert          replace
            d[i][j] = [ (d[i-1][j] + 1), (d[i][j-1] + 1), (d[i-1][j-1] + 1)].min
          end
        end
      end

      d[m][n]
    end

    private

    def self.try_letters(start, finish, word, dict, result)
      ('A'..'Z').each do |c|
        w = "#{start}#{c}#{finish}"
        result << dict[w] if dict[w]
      end
    end
  end
end
