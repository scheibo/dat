module Dat
  class Logger
    def initialize(file=nil, timed=true)
      @timed = timed
      @file = file ? file : $stdout
      @file.puts "#/usr/bin/env ruby"
      @file.flush
    end

    def log(str, is_literal=false)
      if is_literal
        @file.puts str
      else
        @file.puts str.scan(/^.*/).map {|l| "# #{@timed ? "#{Time.now} " : ""}#{l}"}.join("\n")
      end
      @file.flush
    end
  end
end
