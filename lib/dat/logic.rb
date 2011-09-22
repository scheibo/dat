module Dat
  module Pure
    class Logic

      MIN_SIZE = 3

      WEIGHT_THRESHOLD = 0.7
      NUM_CHARS = 4

      def initialize(dict, opt={})
        @dict = dict

        @add = opt.fetch(:add, true)
        @replace = opt.fetch(:replace, true)
        @delete = opt.fetch(:delete, true)
        @transpose = opt.fetch(:transpose, false)

        @min_size = opt.fetch(:min_size, MIN_SIZE)
      end

      def perturb(wordstr, used={})
        size = wordstr.size
        result = []

        if @add
          (0..size).each do |i|
            try_letters(wordstr[0,i], wordstr[i,size], wordstr, used, result)
          end
        end

        if @replace
          (0...size).each do |i|
            try_letters(wordstr[0,i], wordstr[i+1,size], wordstr, used, result)
          end
        end

        if @delete
          (0...size).each do |i|
            w = "#{wordstr[0,i]}#{wordstr[i+1,size]}"
            if @dict[w] && !used[w] && size > @min_size
              result << @dict[w]
            end
          end
        end

        if @transpose
          (0...size-1).each do |i|
            w = "#{wordstr[0,i]}#{wordstr[i+1]}#{wordstr[i]}#{wordstr[i+2,size-i-1]}"
            result << w if @dict[w] && !used[w]
          end
        end

        result
      end

      # http://alias-i.com/lingpipe/src/com/aliasi/spell/JaroWinklerDistance.java
      def jaro_winkler(s, t)
        m, n = s.size, t.size
        return (n == 0 ? 1.0 : 0.0) if m == 0

        range = [0, ([m,n].max / 2) - 1].max

        s_matched = Array.new m, false
        t_matched = Array.new n, false

        common = 0
        (0...m).each do |i|
          start = [0, i-range].max
          fin = [i+range+1, n].min
          (start...fin).each do |j|
            next if t_matched[j] || s[i] != t[j]
            s_matched[i], t_matched[j] = true, true
            common += 1
            break
          end
        end
        return 0.0 if common == 0

        transposed = 0
        j = 0
        (0...m).each do |i|
          next if !s_matched[i]
          j += 1 while !t_matched[j]
          transposed += 1 if s[i] != t[j]
          j += 1
        end
        transposed /= 2

        weight = ((common.to_f/m) + (common.to_f/n) + ((common-transposed) / common.to_f)) / 3.0
        return weight if weight <= WEIGHT_THRESHOLD

        max = [NUM_CHARS, [m,n].min].min
        pos = 0
        pos += 1 while (pos < max && s[pos] == t[pos])
        return weight if (pos == 0)

        weight + 0.1 * pos * (1.0 - weight)
      end

      def damlev(s, t)
        m, n = s.size, t.size
        return n if m == 0
        return m if n == 0
        inf = m + n
        h = Array.new(m+2) { Array.new(n+2) }

        h[0][0] = inf
        (0..m).each { |i| h[i+1][1] = i; h[i+1][0] = inf }
        (0..n).each { |j| h[1][j+1] = j; h[0][j+1] = inf }

        da = {}
        (s + t).each_char {|c| da[c] = 0 }

        (1..m).each do |i|
          db = 0
          (1..n).each do |j|
            i1 = da[t[j-1]]
            j1 = db
            d = ( (s[i-1] == t[j-1]) ? 0 : 1)
            db = j if d == 0
            h[i+1][j+1] = [ h[i][j] + d, h[i+1][j] + 1, h[i][j+1] + 1,
                            h[i1][j1] + (i-i1-1) + 1 + (j-j1-1) ].min
          end
          da[s[i-1]] = i
        end

        h[m+1][n+1]
      end

      def leven(s, t)
        m, n = s.size, t.size
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
              #               delete             insert            replace
              d[i][j] = [ (d[i-1][j] + 1), (d[i][j-1] + 1), (d[i-1][j-1] + 1)].min
            end
          end
        end

        d[m][n]
      end

      private

      def try_letters(start, finish, wordstr, used, result)
        ('A'..'Z').each do |c|
          w = "#{start}#{c}#{finish}"
          result << @dict[w] if @dict[w] && !used[w] && w != wordstr
        end
      end
    end
  end
end
