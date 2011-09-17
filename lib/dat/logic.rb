module Dat
  module Pure
    class Logic

      class Stop < Exception; end

      MAX_PATH_DEPTH = 5
      MAX_ALLOWABLE_DISTANCE = 2
      MIN_SIZE = 3

      WEIGHT_THRESHOLD = 0.7
      NUM_CHARS = 4

      def initialize(dict, opt={})
        @dict = dict
        @selected = {}

        @add = opt.fetch(:add, true)
        @replace = opt.fetch(:replace, true)
        @delete = opt.fetch(:delete, true)
        @transpose = opt.fetch(:transpose, false)

        @min_size = opt.fetch(:min_size, MIN_SIZE)
        @max_depth = opt.fetch(:max_depth, MAX_PATH_DEPTH)
        @max_distance = opt.fetch(:max_distance, MAX_ALLOWABLE_DISTANCE)
      end

      def select(word)
        @selected << word
        @selected << word.relatives.to_a
      end

      def perturb(word)
        # TODO should relative logic be placed into perturb?
        size = word.size
        result = []
        if @add
          (0..size).each do |i|
            try_letters(word[0,i], word[i,size], word, result)
          end
        end

        if @replace
          (0...size).each do |i|
            try_letters(word[0,i], word[i+1,size], word, result)
          end
        end

        if @delete
          (0...size).each do |i|
            w = "#{word[0,i]}#{word[i+1,size]}".upcase
            if @dict[w] && size > @min_size)
              result << @dict[w]
            end
          end
        end

        result
      end

      # http://alias-i.com/lingpipe/src/com/aliasi/spell/JaroWinklerDistance.java
      def jaro_winkler(s, t)
        m, n = s.size, t.size
        return (n == 0 ? 1.0 : 0.0) if m == 0

        range = [0, ([m,n].max/2) - 1].max

        s_matched = Array.new m, false
        t_matched = Array.new n, false

        common = 0
        (0...m).each do |i|
          start = [0, i-range].max
          fin = [i+range+1, n].min
          (start...fin).each do |j|
            next if t_matched[j] || s[i] != t[j]
            s_matched[i] = true;
            t_matched[j] = true;
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

        weight = ((common.to_f/m) + (common.to_f/n) + ((common-transposed)/common.to_f))/3.0
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
            h[i+1][j+1] = [ h[i][j]+d, h[i+1][j] + 1, h[i][j+1]+1,
              h[i1][j1] + (i-i1-1) + 1 + (j-j1-1) ].min
          end
          da[s[i-1]] = i
        end
        h[m+1][n+1]
      end

      def leven(s, t)
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
              #               delete           insert             replace
              d[i][j] = [ (d[i-1][j] + 1), (d[i][j-1] + 1), (d[i-1][j-1] + 1)].min
            end
          end
        end

        d[m][n]
      end

      # Returns the distance between the start and the target. Note this is not
      # the minimum distance, merely a distance
      def distance(start, target)
        pth = path(start, target, nil, [])
        pth.size if pth
      end

      # Try to find a path between two words simply by perturbing them. This does
      # not guarantee the *shortest* path, it simply attempts to find a path. The
      # orig_dist parameter helps short circuit our effort if we ever get too far
      # away from the goal. To be extra safe it is important to timeout this
      # function, using an actual interval of time.
      def path(start, target, orig_dist=nil, result=[])
        # TODO need to worry about the RELATIVES of every word we have chosen.
        orig_dist ||= leven(start.get.upcase, target.get.upcase)

        p [start, target, result]

        # We need to stop recursion after a while so we don't end up going through
        # the entire dictionary
        raise Stop if result.size >= @max_depth
        # We also want to stop if we start to get too far away from the word we
        # are targeting. While it is possible we could eventually get to our
        # target, it is more unlikely the further away from it that we get.
        raise Stop if (leven(start.word.upcase, target.word.upcase) - orig_dist) > @max_distanc

        result << start
        # short circuit if we happen to have the case where start is the target
        return result if start.word.upcase == target.word.upcase

        # The heuristic we use is to sort by the Levenshtein distance, as we
        # assume those words with a closer edit distance are likely closer to the
        # target word.
        # This should be parallelizable - if we do spawn a thread for each
        # perturbed word, other than quickly running out of threads, the
        # levenshtein distance calculation is a lot less necessary.
        perturb(start.get).sort_by { |w| leven(w.get.upcase, target.get.upcase) }.each do |word|
          if !result.include?(word)
            begin
              pth = path(word, target, orig_dist, result.clone)
              return pth if pth
            rescue Stop
              break
            end
          end
        end

        # if we get here then the was no path from start to target so we simply
        # return nothing which will end up being nil
        nil
      end

      private

      def try_letters(start, finish, word, result)
        ('A'..'Z').each do |c|
          w = "#{start}#{c}#{finish}".upcase
          result << @dict[w] if @dict[w] and w != word.upcase
        end
      end
    end
  end
end
