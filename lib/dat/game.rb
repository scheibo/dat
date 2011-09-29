$:.unshift(File.expand_path('../../../lib', __FILE__)) unless $:.include?(File.expand_path('../../../lib', __FILE__))
require 'logic'

module Dat

  class Move < RuntimeError; end
  class InvalidMove < Move; end
  class WinningMove < Move; end
  class InvalidGame < RuntimeError; end

  class Game

    START_WORD = 'DAT'
    MIN_PLAYERS = 2

    attr_reader :played, :used, :dict, :logic, :last, :min_size
    alias history played

    def initialize(logger, opt={})
      @logger = logger
      printable_opt = opt.clone
      printable_opt[:players] = printable_opt[:players].map(&:to_s)
      @logger.log("game = Dat::Game.new(Dat::Logger.new[0], #{printable_opt})", true)

      if !opt[:players] || opt[:players].size < MIN_PLAYERS
        raise InvalidGame, "Not enough players in the game."
      else
        num_players = opt[:players].size
      end

      # Mix of player jids and bot objects
      @players = {}
      @player_order = opt[:players]
      opt[:players].each_with_index do |p, i|
        @players[p] = i
      end

      @dict = opt[:dict] || Dict.new
      @logic = Dat::Logic.new(@dict, opt)

      @last = opt[:start_word] || START_WORD
      @last.upcase!
      @played = [@last]
      @used = {@last => true}

      @start = Time.now
      @times = []
    end

    def forfeit(player)
      @logger.log("game.forfeit(\"#{player}\")", true)

      idx = @players[player]
      @players.delete player
      @player_order[idx] = nil
      @player_order.compact!

      if @players.size == 1
        @won = @player_order[0]
      end

      msg = "Player #{idx+1} (#{player}) has forfeited."
      msg << " Player #{@players[@won]+1} (#{@won}) wins." if @won
      msg
    end

    def time
      Time.now - @start
    end

    def turn
      @played.size
    end

    def whos_turn
      @player_order[turn % @players.size]
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

    def next_move!
      next_player = whos_turn
      if next_player.respond_to?(:bot?) && next_player.bot?
        next_player.move << "\n" << next_move!.to_s
      end
    end

    def play(player, word)
      @logger.log("game.play(\"#{player}\", \"#{word}\")", true)

      expected_player = whos_turn
      raise InvalidMove, "#{player} is not a valid player." if !@players[player]
      raise InvalidMove, "Cannot play out of turn. It is player #{@players[expected_player]}'s (#{expected_player}) move." if player != expected_player
      raise InvalidMove, "The game has already been won by #{@won}." if @won

      if @dict[word] && !@used[word] && @logic.leven(word, @last) == 1
        t = Time.now
        @times << ("%.1f" % (t-@start))
        @start = t
        @last = word
        @played << word
        @used[word] = true
        @dict[word].relatives.map { |r| @used[r.get] = true }

        if @logic.perturb(@last, @used).empty?
          @won = player
          raise WinningMove, "Player #{@players[@won]+1} (#{@won}) wins."
        end

        next_move!
      else
        raise InvalidMove, "Move is invalid."
      end
    end

  end
end
