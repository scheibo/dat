$:.unshift(File.expand_path('../../../lib', __FILE__)) unless $:.include?(File.expand_path('../../../lib', __FILE__))
require 'logger'
require 'game'

module Dat
  class LogGame < Game
    def initialize(opt={})
      super(Logger.new.create(0), opt)
    end

    def play(player, word)
      super(player, word)
    rescue Move => m
        @logger.log(m.message)
    end

  end
end
