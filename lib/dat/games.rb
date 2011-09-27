$:.unshift(File.expand_path('../../dat', __FILE__)) unless $:.include?(File.expand_path('../../dat', __FILE__))
require 'dict'
require 'bots'
require 'game'
require 'thread'

module Dat

  class NoGameError < RuntimeError
    def message
      "Game does not exist"
    end
  end

  class Games
    attr_reader :dict

    def initialize
      @mutex = Mutex.new
      @games = {}
      @dict = Dict.new
      @gid = 0
    end

    def [](gid)
      @games.fetch(gid)
    rescue KeyError
      raise NoGameError
    end

    def game(gid)
      @games[gid][0]
    end

    def bot(gid)
      @games[gid][1]
    end

    def add(opt={})
      opt.merge(:dict => @dict)
      @mutex.synchronize { @gid += 1 }
      game = Game.new(opt)
      # TODO right now only one option, to make a simple bot - needs more
      bot = SimpleBot.new(game)
      @games[@gid] = [game, bot]
      @gid
    end
  end
end