$:.unshift(File.expand_path('../../../lib', __FILE__)) unless $:.include?(File.expand_path('../../../lib', __FILE__))
require 'bot'

class SimpleBot < Dat::Bot
  def move
    @game.logic.perturb(@game.last, @game.used).first
  end
end
