$:.unshift(File.expand_path('../../../dat', __FILE__)) unless $:.include?(File.expand_path('../../../dat', __FILE__))
require 'xmpp4r'
require 'interface'
require 'logger'

module Dat
  class ChatBot

    DATBOT_INFO = { :jid => 'dat@scheibo.com', :password => 'robotdat' }

    def initialize(log_path_prefix=nil)
      @logger = Logger.new(log_path_prefix)
      @interface = Interface.new(@logger)
    end

    def run
      @client = Jabber::Client.new(Jabber::JID.new(DATBOT_INFO[:jid]))
      @client.connect
      @client.auth(DATBOT_INFO[:password])
      @client.send(Jabber::Presence.new)

      @client.add_message_callback do |m|
        if m.type != :error && !m.composing? && !m.body.to_s.strip.empty?
          @logger[from].log(m.body)
          response = @interface.respond(m.from, m.body).to_s.strip
          if !response.empty?
            msg = Jabber::Message.new(m.from, response)
            msg.set_type(:chat)
            @client.send(msg)
            @logger[from].log(msg)
          end
        end
      end

      Thread.stop
      @client.stop
    end
  end
end
