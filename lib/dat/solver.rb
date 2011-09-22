$:.unshift(File.expand_path('../../dat', __FILE__)) unless $:.include?(File.expand_path('../../dat', __FILE__))
require 'logic'

module Dat
  class Solver

    class Stop < Exception; end

    MAX_PATH_DEPTH = 5
    MAX_ALLOWABLE_DISTANCE = 2

    WEIGHT_THRESHOLD = 0.7
    NUM_CHARS = 4

    def initialize(logic)
      @logic = logic
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
      orig_dist ||= @logic.leven(start.get, target.get)

      p [start, target, result]

      # We need to stop recursion after a while so we don't end up going through
      # the entire dictionary
      raise Stop if result.size >= @max_depth
      # We also want to stop if we start to get too far away from the word we
      # are targeting. While it is possible we could eventually get to our
      # target, it is more unlikely the further away from it that we get.
      raise Stop if (@logic.leven(start.word, target.word) - orig_dist) > @max_distance

      result << start
      # short circuit if we happen to have the case where start is the target
      return result if start.word.upcase == target.word.upcase

      # The heuristic we use is to sort by the Levenshtein distance, as we
      # assume those words with a closer edit distance are likely closer to the
      # target word.
      # This should be parallelizable - if we do spawn a thread for each
      # perturbed word, other than quickly running out of threads, the
      # levenshtein distance calculation is a lot less necessary.
      @logic.perturb(start.get).sort_by { |w| @logic.leven(w.get.upcase, target.get.upcase) }.each do |word|
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

  end
end
