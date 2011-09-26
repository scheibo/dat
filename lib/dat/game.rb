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

    def initialize(num_players=2, start_word=nil, dict=nil)
      @players = Array.new(num_players) { |i| i+1 }

      @dict = dict || Dict.new
      @logic = Logic.new(@dict)

      @last = start_word || START_WORD
      @played = [@last]
      @used = {@last => true}

      @start = Time.now
      @times = []
    end

    def forfeit(player)
      @players[player] = nil
      if @players.compact.size == 1
        @won = @players.compact[0]
      end
      @won
    end

    def time
      Time.now - @start
    end

    def turn
      @played.size
    end

    # TODO write tests for this to verify that it works
    def whos_turn
      @players[(turn % @players.flatten.size) + 1]
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
      raise InvalidMove, "The game has already been won by #{@won}" if @won
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
          @won = whos_turn-1
          raise WinningMove, "Player #{@won} wins"
        end
      else
        raise InvalidMove, "Move is invalid"
      end
    end

  end
end
