$:.unshift(File.expand_path('../../dat', __FILE__)) unless $:.include?(File.expand_path('../../dat', __FILE__))
require 'dict'
require 'logic'

module Dat

  class Move < RuntimeError; end
  class InvalidMove < Move; end
  class WinningMove < Move; end

  class Game

    START_WORD = 'dat'

    attr_reader :played, :used, :dict, :logic, :last
    alias history played

    def initialize(num_players=2, start=nil)
      @num_players = num_players

      @dict = Dict.new
      @logic = Logic.new(@dict)

      @last = start || START_WORD
      @played = [@last]
      @used = {@last => true}

      @start = Time.now
      @times = []
    end

    def turn
      @played.size
    end

    def whos_turn
      (turn % @num_players) + 1
    end

    def to_s
      display(:all)
    end

    def display(num, time=false)
      items = (num == :all ? @played : @played.last(num))
      size = items.size
      result = []
      items.each_with_index do |item, i|
        if time && i != 0
          result << "#{item} (#{@times[i-1]})"
        else
          result << "#{item}"
        end
        result << " -> " if i != size-1
      end
      result << " -> ???" if !@won
      result.join
    end

    def play(word)
      raise InvalidMove, "Game has already been won" if @won
      # @dict[word] && @logic.perturb(@last, @used).include?(word)
      if @dict[word] && !@used[word] && @logic.leven(word, @last) == 1
        t = Time.now
        @times << ("%.1f" % (t-@start))
        @start = t
        @last = word
        @played << word
        @used[word] = true
        @dict[word].relatives.map { |r| @used[r] = true }

        # check if winning
        if @logic.perturb(@last, @used).empty?
          @won = true
          raise WinningMove, "Player #{whos_turn-1} wins"
        end
      else
        raise InvalidMove, "Move is invalid"
      end
    end

  end
end
