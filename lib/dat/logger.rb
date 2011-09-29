module Dat
  class Logger

    def initialize(path_prefix=nil, timed=true)
      @timed = timed
      @path_prefix = path_prefix
      @logs = {}
    end

    def [](lid)
      @logs[lid] ||= Log.new(lid, @path_prefix, @timed)
    end

    class Log
      def initialize(lid, path_prefix, timed)
        @timed = timed
        @file = path_prefix ? File.open("#{path_prefix}/dat-#{lid}-#{Time.now.to_i}.log", "a") : $stdout

        @file.puts "#!/usr/bin/env ruby"
        @file.puts "$.unshift('/Users/kjs/Code/src/dat/lib/')" # TODO remove once installed as gem
        @file.puts "require 'dat'\n"
        @file.flush
      end

      def log(str, is_literal=false)
        if is_literal
          @file.puts(str)
        else
          @file.puts( str.scan(/^.*/).map {|l| "# #{@timed ? "#{Time.now} " : ""}#{l}"}.join("\n"))
        end
        @file.flush
      end
    end

  end
end
