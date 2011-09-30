$:.unshift(File.expand_path('../../dat', __FILE__)) unless $:.include?(File.expand_path('../../dat', __FILE__))
require 'dict'
require 'bots'
require 'game'

module Dat

  class NoGameError < RuntimeError; end

  class Games
    attr_reader :dict

    def initialize(logger)
      @games = {}
      @dict = Dict.new
      @logger = logger
    end

    def check!(gid)
      if @games[gid] && @games[gid].won
        raise NoGameError, "Game has been won."
      end
    end

    def [](gid)
      @games.fetch(gid)
    rescue KeyError
      raise NoGameError, "Game does not exist"
    end

    def add(gid, opt={})
      opt.merge(:dict => @dict)

      game = Game.new(@logger.create(gid),  opt)

      opt[:players].each do |p|
        if p.respond_to?(:bot?) && p.bot?
          p.init(game)
        end
      end

      @games[gid] = game
      @games[gid].next_move!
    end
  end
end
