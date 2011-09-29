$:.unshift(File.expand_path('../../dat', __FILE__)) unless $:.include?(File.expand_path('../../dat', __FILE__))
require 'games'
require 'game'
require 'version'
require 'bots'

module Dat

  class NotImplementedError < RuntimeError; end

  class Interface
    RECENT_AMOUNT = 4

    def initialize(logger)
      @games = Games.new(logger)
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
        when 'end', 'forfeit' then forfeit(from)
        when 'define', 'dict', 'd' then dict_entry(args)
        when 'recent' then recent(from)
        when 'trecent' then recent(from, true)
        when 'history' then history(from)
        when 'thistory' then history(from, true)
        when 'time' then time(from)
        else nil
        end
      when '?' then define(msg)
      when '@' then move(from, msg)
      else nil
      end
    rescue NoGameError => e
      e.message
    rescue
      # TODO debugging code
      puts $!.message
      puts $!.backtrace.join("\n")
      "ERROR"
    end

    def new_game(from, args=[], type=nil)
      opt = {}
      opt[:delete] = false if type == :hard
      opt[:players] = [from]
      args.each do |arg|
        k, v = arg.split(":")
        if k == 'bot'
          case v
          when 'simple' then opt[:players] << SimpleBot.new
          when 'hard' then raise NotImplementedError, "Hard is not implemented yet."
          else raise NotImplementedError, "No other bots are implemented."
          end
        else
          opt[k] = v
        end
      end

      if opt[:players].size < Dat::Game::MIN_PLAYERS
        opt[:players] << SimpleBot.new # Default Bot
      end

      @games.add(from, opt)
    end

    def define(word)
      @games.dict[word.upcase].definition.capitalize rescue "Not a word."
    end

    def dict_entry(args)
      result = []
      args.each do |w|
        result << @game.dict[word.upcase].to_dict_entry if @game.dict[word.upcase]
      end
      result.join("\n")
    end

    def move(from, word)
      @games[from].play(from, word.strip.upcase)
    rescue Move => e
      e.message
    rescue NoGameError => n
      w = word.strip.upcase
      if @games.dict[w] || w == Dat::Game::START_WORD
        new_game(:start_word => w)
      else
        n.message
      end
    end

    def recent(gid, timed=false)
      @games[gid].display(RECENT_AMOUNT, timed)
    end

    def history(gid, timed=false)
      @games[gid].display(:all, timed)
    end

    def forfeit(gid)
      @games[gid].forfeit(gid)
    end

    def time(gid)
      @games[gid].time
    end
  end
end
