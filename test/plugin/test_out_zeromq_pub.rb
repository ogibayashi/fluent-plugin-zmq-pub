require 'helper'
require 'ffi-rzmq'

class ZmqPubOutputTest < Test::Unit::TestCase
  def setup
    Fluent::Test.setup
    @context = ZMQ::Context.new(1)
    @subscriber = @context.socket(ZMQ::SUB)
    @subscriber.connect('tcp://localhost:5556')
  end

  def teardown
    @subscriber.close
    @context.terminate
  end
  
  CONFIG = %[
      pubkey ${tag}:${key1}
      bindaddr tcp://*:5556
  ]

  CONFIG_BY_TAG = %[
      pubkey ${tag}
      bindaddr tcp://*:5556
  ]
  
  def create_driver(conf = CONFIG, tag='test')
    Fluent::Test::BufferedOutputTestDriver.new(Fluent::ZmqPubOutput, tag).configure(conf)
  end
  
  def test_configure
    d = create_driver

    assert_equal '${tag}:${key1}', d.instance.pubkey
    assert_equal 'tcp://*:5556', d.instance.bindaddr
  end
  
  def test_format
    d = create_driver
    
    time = Time.parse("2011-01-02 13:14:15 UTC").to_i
    d.emit({"key1"=>"aaa"}, time)
    d.emit({"key1"=>"bbb", "key2"=>3}, time)
    
    d.expect_format ["test",time.to_i,{ "key1" => "aaa"}].to_msgpack
    d.expect_format ["test",time.to_i,{ "key1" => "bbb", "key2" => 3}].to_msgpack
    
    d.run
  end
  
  def test_write
    d = create_driver
    @subscriber.setsockopt(ZMQ::SUBSCRIBE,"test:aaa")
    
    time = Time.parse("2011-01-02 13:14:15 UTC").to_i
    d.emit({"key1"=>"aaa"}, time)
    d.emit({"key1"=>"bbb", "key2"=>3}, time)
    
    d.run
    sleep 1

    msg = ZMQ::Message.new
    @subscriber.recvmsg(msg,ZMQ::DONTWAIT)
    (key, record) = msg.copy_out_string.split(" ",2)
    assert_equal ["test",time.to_i,{ "key1" => "aaa"}].to_msgpack, record

  end


  # def test_bulk_write
  #   d = create_driver(CONFIG_BY_TAG)
  #   @subscriber.setsockopt(ZMQ::SUBSCRIBE,"test")
    
  #   time = Time.parse("2011-01-02 13:14:15 UTC").to_i
  #   d.emit({"key1"=>"aaa"}, time)
  #   d.emit({"key1"=>"bbb", "key2"=>3}, time)
    
  #   d.run
  #   sleep 1

  #   msg = @subscriber.recv_string(ZMQ::NOBLOCK)
  #   (key, record) = msg.split(" ",2)
  #   assert_equal ["test",time.to_i,{ "key1" => "aaa"}].to_msgpack, record
  # end
end


