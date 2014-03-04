require "fluent/plugin/out_forward"
require "fluent/plugin/buf_memory"
require "fluent/plugin/buf_file"
require "base64"
require "openssl"

module Fluent

  def encrypt(key, iv, data)
    cipher = OpenSSL::Cipher::AES.new(256, :CBC).encrypt
    cipher.key = key
    cipher.iv = iv
    cipher.encrypt
    Base64.encode64(cipher.update(data) + cipher.final)
  end

  MemoryBufferChunk.class_eval do
    def write_to(io)
      io.write(encrypt(@data))
    end
  end

  FileBufferChunk.class_eval do
    def write_to(io)
      open {|i|
        FileUtils.copy_stream(encrypt(i), io)
      }
    end
  end

  class AESForwardOutput < ForwardOutput
    Fluent::Plugin.register_output('aes_forward', self)

    config_param :key, :string, default: ""
    config_param :iv, :string, default: ""

    def send_data(node, tag, chunk)
      sock = connect(node)
      begin
        opt = [1, @send_timeout.to_i].pack('I!I!')  # { int l_onoff; int l_linger; }
        sock.setsockopt(Socket::SOL_SOCKET, Socket::SO_LINGER, opt)

        opt = [@send_timeout.to_i, 0].pack('L!L!')  # struct timeval
        sock.setsockopt(Socket::SOL_SOCKET, Socket::SO_SNDTIMEO, opt)

        # beginArray(2)
        sock.write FORWARD_HEADER

        # writeRaw(tag)
        sock.write tag.to_msgpack  # tag

        chunk.encrypt!(@key, @iv)

        # beginRaw(size)
        sz = chunk.size
        #if sz < 32
        #  # FixRaw
        #  sock.write [0xa0 | sz].pack('C')
        #elsif sz < 65536
        #  # raw 16
        #  sock.write [0xda, sz].pack('Cn')
        #else
        # raw 32
        sock.write [0xdb, sz].pack('CN')
        #end

        # writeRawBody(packed_es)
        chunk.write_to(sock)

        node.heartbeat(false)
      ensure
        sock.close
      end
    end
  end
end
