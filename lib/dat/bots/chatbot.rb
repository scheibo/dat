$:.unshift(File.expand_path('../../../dat', __FILE__)) unless $:.include?(File.expand_path('../../../dat', __FILE__))
require 'xmpp4r'
require 'interface'

module Dat
  class ChatBot

    DATBOT_INFO = { :jid => 'dat@scheibo.com', :password => 'robotdat' }

    def initialize
      @interface = Interface.new
    end

    def run
      @client = Jabber::Client.new(Jabber::JID.new(DATBOT_INFO[:jid]))
      @client.connect
      @client.auth(DATBOT_INFO[:password])
      @client.send(Jabber::Presence.new)

      @client.add_message_callback do |m|
        if m.type != :error && !m.composing? && !m.body.to_s.strip.empty?
          response = @interface.respond(m.from, m.body).to_s.strip
          if !response.empty?
            msg = Jabber::Message.new(m.from, response)
            msg.set_type(:chat)
            @client.send(msg)
          end
        end
      end

      Thread.stop
      @client.stop
    end
  end
end
