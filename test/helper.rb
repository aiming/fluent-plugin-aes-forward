require 'bundler'

Bundler.setup(:default, :test)
Bundler.require(:default, :test)

require 'fluent/test'
require 'test/unit'

$:.unshift(File.join(File.dirname(__FILE__), '../lib'))
$:.unshift(File.dirname(__FILE__))

def unused_port
  s = TCPServer.open(0)
  port = s.addr[1]
  s.close
  port
end

require 'base64'
require 'fluent/plugin/in_aes_forward'
require 'fluent/plugin/out_aes_forward'
