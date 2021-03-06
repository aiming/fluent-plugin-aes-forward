require "openssl"

class AESForwardOutputTest < Test::Unit::TestCase
  def setup
    Fluent::Test.setup
  end

  CONFIG = %[
    send_timeout 51
    key  hogehogehogehogehogehogehogehoge
    iv   mogemogemogemogemogemogemogemoge
    <server>
      name test
      host 127.0.0.1
      port 13999
    </server>
  ]

  def create_driver(conf=CONFIG)
    Fluent::Test::OutputTestDriver.new(Fluent::AESForwardOutput) do
      def write(chunk)
        chunk.read
      end
    end.configure(conf)
  end
  
  def test_configure
    d = create_driver
    nodes = d.instance.nodes
    assert_equal 51, d.instance.send_timeout
    assert_equal :udp, d.instance.heartbeat_type
    assert_equal 1, nodes.length
    node = nodes.first
    assert_equal "test", node.name
    assert_equal '127.0.0.1', node.host
    assert_equal 13999, node.port
  end

  def test_configure_tcp_heartbeat
    d = create_driver(CONFIG + "\nheartbeat_type tcp")
    assert_equal :tcp, d.instance.heartbeat_type
  end


end
