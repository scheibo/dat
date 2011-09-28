$:.unshift(File.expand_path('../../dat', __FILE__)) unless $:.include?(File.expand_path('../../dat', __FILE__))
require 'dict'
require 'bots'
require 'game'

module Dat

  class NoGameError < RuntimeError; end

  class Games
    attr_reader :dict

    def initialize
      @games = {}
      @dict = Dict.new
    end

    def [](gid)
      @games.fetch(gid)
    rescue KeyError
      raise NoGameError, "Game does not exist"
    end

    def add(gid, opt={})
      opt.merge(:dict => @dict)

      game = Game.new(opt)

      opt[:players].each do |p|
        if p.respond_to(:bot?) and p.bot?
          p.init(game)
        end
      end

      @games[gid] = game
    end
  end
end
