module Dat
  class Bot
    def init(game)
      @game = game
    end

    def bot?
      true
    end

    def to_s
      "Bot-#{object_id}"
    end

    def move
      # Implement this function
    end
  end
end
