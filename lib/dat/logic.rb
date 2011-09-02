module Dat
  class Logic
    def self.perturb(word, dict, opt={})
      word.upcase!
      min_size = opt[:min_size]
      opt.default = true
      #c_pertub(word, dict, min_size) if opt[:add] && opt[:replace] && opt[:delete]

      size = word.size
      result = []

      fin = nil
      (size+1).times do |i|
        start = word[0,i]
        ('A'..'Z').each do |c|
          fin = word[i,size]
          add_if_in_dict(dict, "#{start}#{c}#{fin}", result) if opt[:add]
          if (i < size)
            fin = word[i+1,size]
            add_if_in_dict(dict, "#{start}#{c}#{fin}", result) if opt[:replace]
          end
        end
        if (i < size)
          add_if_in_dict(dict, "#{start}#{fin}", result) if opt[:delete] && (!min_size || size-1 > min_size)
        end
      end

      result
    end

    private

    def self.add_if_in_dict(dict, word, result)
      result << dict[word] if dict[word]
    end
  end
end
