$:.unshift(File.expand_path('../../dat', __FILE__)) unless $:.include?(File.expand_path('../../dat', __FILE__))
require 'games'
require 'version'

module Dat
  class Interface
    RECENT_AMOUNT = 4

    def initialize
      @games = Games.new
      @gids = {}
    end

    def get_gid(from)
      @gids.fetch(from)
    rescue KeyError
      raise NoGameError
    end

    def help
      <<-END.gsub(/^\s{8}/, "")
        dat - #{Dat::VERSION}

        !<command> - send a command to dat bot
        ?<word> - define the word if it exists
        @<word> - play a word

        Commands:
          help - displays this help
          end/forfeit - forfeits the game
          recent/trecent - displays the words recently played (t prefix for times)
          history/thistory - displays the entire game history (t prefix for times)
          time - how long it has been since the last move
      END
    end

    def respond(from, message)
      prefix, msg, *args = message[0], *message[1, message.size].split
      case prefix
      when '!' then
        case msg
        when 'help' then help
        when 'dat', 'new' then new_game(from, args)
        when 'hard' then new_game(from, args, :hard)
        when 'end', 'forfeit' then forfeit(get_gid(from))
        when 'recent' then recent(get_gid(from))
        when 'trecent' then recent(get_gid(from), true)
        when 'history' then history(get_gid(from))
        when 'thistory' then history(get_gid(from), true)
        when 'time' then time(get_gid(from))
        when 'u' then used(get_gid(from))
        else nil
        end
      when '?' then define(msg)
      when '@' then move(from, msg)
      else nil
      end
    rescue NoGameError => e
      e.message
    rescue
      puts $!.backtrace.join("\n")
      "ERROR"
    end

    def new_game(from, args=[], type=nil)
      opt = {}
      opt[:delete] = false if type == :hard
      args.each do |arg|
        k, v = arg.split(":")
        opt[k] = v
      end
      gid = @games.add(opt)
      @gids[from] = gid
      @games.bot(gid).move
    end

    def define(word)
      @games.dict[word.upcase].definition.capitalize rescue "Not a word"
    end

    def move(from, word)
      gid = get_gid(from)
      @games.game(gid).play(word.strip.upcase)
      @games.bot(gid).move
    rescue InvalidMove, WinningMove => e
      e.message
    rescue NoGameError => n
      if @games.dict[word.strip.upcase]
        new_game(:start_word => word.strip.upcase)
        @games.bot(gid).move
      else
        e.message
      end
    end

    def recent(gid, timed=false)
      @games.game(gid).display(RECENT_AMOUNT, timed)
    end

    def history(gid, timed=false)
      @games.game(gid).display(:all, timed)
    end

    def forfeit(gid)
      winner = @games.game(gid).forfeit(1)
      "Player #{winner} wins"
    end

    def used(gid)
      @games.game(gid).used.keys.join ", "
    end

    def time(gid)
      @games.game(gid).time
    end
  end
end
