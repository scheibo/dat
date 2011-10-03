module Dat
  class Leaves
    def initialize(game, depth=4)
      @game = game
      @logic = @game.logic
      @dict = @game.dict

      @depth = depth
      @leaves = Array.new(@depth+1) { {} }

      calculate
    end

    def [](word)
      1.upto(@depth) do |i|
        leaf = @leaves[i][word]
        return leaf if leaf
      end
      nil
    end

    def leaf?(word)
      level(word)
    end

    def level(word)
      1.upto(@depth) do |i|
        leaf = @leaves[i][word]
        return i if leaf
      end
    end

    def get(size)
      return nil if size > @depth
      @leaves[size]
    end

    def calculate
      @dict.each do |k,v|
        result = @logic.perturb(k)
        size = result.size
        @leaves[size][k] = result if size <= @depth
      end
    end

    def update
      @game.last.relatives.clone.add(@game.last).each do |w|
      #@game.used.each do |u|
        @logic.perturb(u.get, @game.used).each do |w|
          1.upto(@depth) do |i|
            @leaves[i].delete(u.get) if @leaves[i][u.get]
            leaf = @leaves[i][w.get]
            if leaf && leaf.include?(w)
              (@leaves[i-1][w.get] = leaf.clone).delete(w)
              @leaves[i].delete(w.get)
            end
          end
        end
      end
      @leaves[0] # Immediate winning moves
    end
  end
end
