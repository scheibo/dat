$:.unshift(File.expand_path('../../dat', __FILE__)) unless $:.include?(File.expand_path('../../dat', __FILE__))
require 'dict'
require 'game'

module Dat
  class Games
    attr_reader :dict

    def initialize
      @games = {}
      @dict = Dict.new
    end

    def [](player)
      @games[player] ||= Game.new(@dict)
    end

    def []=(player, game)
      @games[player] = game(@dict)
    end
  end
end
