def perturb(word, dict, opt={})
  min_size = opt[:min_size]
  opt.default = true
  size = word.size
  result = []
  if opt[:add]
    (0..size).each do |i|
      result << try_letters(word[0,i], word[i,size], word,  dict)
    end
  end

  if opt[:replace]
    (0...size).each do |i|
      result << try_letters(word[0,i], word[i+1,size], word, dict)
    end
  end

  if opt[:delete]
    (0...size).each do |i|
      w = "#{word[0,i]}#{word[i+1,size]}"
      if dict[w] && (!min_size || w.size >= min_size)
        result << w
      end
    end
  end

  result.flatten
end

def try_letters(start, finish, word, dict)
  result = []
  ('a'..'z').each do |c|
    w = "#{start}#{c}#{finish}"
    if dict[w] && w != word
      result << w
    end
  end
  result
end

dictionary = {}
ARGF.each_line do |line|
  space = line.index " "
  if space
    word, defn = line[0...space], line[space+1..line.size].chomp
  else
    word, defn = line.chomp, ""
  end
  dictionary[word.downcase] = defn
end

dictionary.each do |k,v|
  unless perturb(k, dictionary, :min_size => 2).size > 0
    puts k
  end
end
