require "fluent/plugin/in_forward"
require "openssl"
require "base64"

module Fluent
  class AESForwardInput < ForwardInput
    Fluent::Plugin.register_input('aes_forward', self)

    config_param :key, :string, default: ""
    config_param :iv, :string, default: ""

    def decrypt_data(record)
      decipher = OpenSSL::Cipher::AES.new(256, :CBC).decrypt
      decipher.key = @key
      decipher.iv = @iv
      decipher.update(Base64.decode64(record)) + decipher.final
    end

    def on_message(msg)
      if msg.nil?
        # for future TCP heartbeat_request
        return
      end

      # TODO format error
      tag = msg[0].to_s
      entries = decrypt_data(msg[1])

      if entries.class == String
        # PackedForward
        es = MessagePackEventStream.new(entries, @cached_unpacker)
        Engine.emit_stream(tag, es)

      elsif entries.class == Array
        # Forward
        es = MultiEventStream.new
        entries.each {|e|
          record = e[1]
          next if record.nil?
          time = e[0].to_i
          time = (now ||= Engine.now) if time == 0
          es.add(time, record)
        }
        Engine.emit_stream(tag, es)

      else
        # Message
        record = msg[2]
        return if record.nil?
        time = msg[1]
        time = Engine.now if time == 0
        Engine.emit(tag, time, record)
      end
    end
  end
end
