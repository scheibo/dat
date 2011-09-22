$:.unshift(File.expand_path('../../dat', __FILE__)) unless $:.include?(File.expand_path('../../dat', __FILE__))
require 'dict'
require 'logic'

module Dat

  class Move < RuntimeException; end
  class InvalidMove < Move; end
  class WinningMove < Move; end

  class Game

    START_WORD = 'dat'

    attr_reader :played, :used
    alias played history

    def initialize(num_players=2, start=nil)
      @num_players = num_players

      @dict = Dict.new
      @logic = Logic.new(@dict)

      @last = start || START_WORD
      @played = [@last]
      @used = {@last => true}
    end

    def turn
      @played.size
    end

    def whos_turn
      (turn % @num_players) + 1
    end

    def to_s
      result = @played.join " -> "
      result << " -> ???" if !@won
      result
    end

    def play(word)
      raise InvalidMove, "Game has already been won" if @won
      # @dict[word] && @logic.perturb(@last, @used).include?(word)
      if @dict[word] && !@used[word] && @logic.leven(word, @last) == 1
        @last = word
        @played << word
        @used[word] = true
        @dict[word].relatives.map { |r| @used[r] = true }

        # check if winning
        @won = true && raise WinningMove, "Player #{whos_turn-1} wins" if @logic.perturb(@last, @used).empty?
      else
        raise InvalidMove, "Move is invalid"
      end
    end

  end
end
