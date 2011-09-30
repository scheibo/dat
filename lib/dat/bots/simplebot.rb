$:.unshift(File.expand_path('../../bots', __FILE__)) unless $:.include?(File.expand_path('../../bots', __FILE__))
require 'bot'

module Dat
  class SimpleBot < Bot
    def move
      word = @game.logic.perturb(@game.last, @game.used).sample.to_s
      @game.play(self, word)
      word
    rescue WinningMove => e
      word << "\n" << e.message
    end

    def to_s
      "SimpleBot-#{object_id}"
    end
  end
end
