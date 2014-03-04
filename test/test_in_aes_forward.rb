require_relative 'helper'

class InAESForwardTest < Test::Unit::TestCase
  def setup
    Fluent::Test.setup
  end

  PORT = unused_port
  KEY = "hogehogehogehogehogehogehogehoge"
  IV = "mogemogemogemogemogemogemogemoge"

  CONFIG = %[
    key  #{KEY}
    iv   #{IV}
    port #{PORT}
    bind 127.0.0.1
  ]

  def create_driver(conf=CONFIG)
    Fluent::Test::InputTestDriver.new(Fluent::AESForwardInput).configure(conf)
  end

  def test_configure
    d = create_driver
    assert_equal PORT, d.instance.port
    assert_equal '127.0.0.1', d.instance.bind
  end

  def connect
    TCPSocket.new('127.0.0.1', PORT)
  end

  def encrypt_data(data)
    cipher = OpenSSL::Cipher::AES.new(256, :CBC).encrypt
    cipher.key = KEY
    cipher.iv = IV
    Base64.encode64(cipher.update(Marshal.dump(data)) + cipher.final)
  end

  def test_time
    d = create_driver

    time = Time.parse("2011-01-02 13:14:15 UTC").to_i
    Fluent::Engine.now = time

    d.expect_emit "tag1", time, { "a" => 1 }
    d.expect_emit "tag2", time, { "a" => 2 }

    d.run do
      d.expected_emits.each do |tag, time, record|
        send_data([tag, 0, record].map { |x| return encrypt_data(x) }.to_msgpack)
      end
      sleep 0.5
    end
  end

  def test_message
    d = create_driver

    time = Time.parse("2011-01-02 13:14:15 UTC").to_i

    d.expect_emit "tag1", time, { "a" => 1 }
    d.expect_emit "tag2", time, { "a" => 2 }

    d.run do
      d.expected_emits.each do |tag, time, record|
        send_data([tag, time, record].map { |x| return encrypt_data(x) }.to_msgpack)
      end
      sleep 0.5
    end
  end

  def test_forward
    d = create_driver

    time = Time.parse("2011-01-02 13:14:15 UTC").to_i

    d.expect_emit "tag1", time, { "a" => 1 }
    d.expect_emit "tag1", time, { "a" => 2 }

    d.run do
      entries = []
      d.expected_emits.each do |tag, time, record|
        entries << [time, record]
      end
      send_data(["tag1", entries].map { |x| return encrypt_data(x) }.to_msgpack) 
      sleep 0.5
    end
  end

  def test_packed_forward
    d = create_driver

    time = Time.parse("2011-01-02 13:14:15 UTC").to_i

    d.expect_emit "tag1", time, { "a" => 1 }
    d.expect_emit "tag1", time, { "a" => 2 }

    d.run do
      entries = ''
      d.expected_emits.each do |tag, time, record|
        [time, record].to_msgpack(entries)
      end
      send_data(["tag1", entries].map { |x| return encrypt_data(x) }.to_msgpack)
      sleep 0.5
    end
  end

  def test_message_json
    d = create_driver

    time = Time.parse("2011-01-02 13:14:15 UTC").to_i

    d.expect_emit "tag1", time, { "a" => 1 }
    d.expect_emit "tag2", time, { "a" => 2 }

    d.run do
      d.expected_emits.each do |tag, time, record|
        send_data([tag, time, record].map { |x| return encrypt_data(x) }.to_json)
      end
      sleep 0.5
    end
  end

  def send_data(data)
    io = connect
    begin
      io.write data
    ensure
      io.close
    end
  end

end
