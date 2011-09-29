module Dat
  class Logger
    def initialize(opt={})
      @opt = opt.merge(:timed => true)
      @logs = {}
    end

    def [](lid)
      @logs[lid] ||= Logger::Log.new(lid, @opt)
    end

    class Log
      def initialize(lid, opt)
        @timed = opt[:timed]
        if opt[:null]
          @file = File.open('/dev/null', 'w')
        elsif opt[:path]
          @file = File.open("#{opt[:path]}/dat-#{lid}-#{Time.now.to_i}.log", "a")
        else
          @file = $stdout
        end

        @file.puts "#!/usr/bin/env ruby"
        @file.puts "$:.unshift('/Users/kjs/Code/src/dat/lib/')" # TODO remove once installed as gem
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
