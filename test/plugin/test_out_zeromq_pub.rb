require 'helper'
require 'ffi-rzmq'
require 'fluent/test/driver/output'

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

  CONFIG_BULK = %[
      pubkey ${tag}:${key1}
      bindaddr tcp://*:5556
      bulk_send true
  ]

  CONFIG_BY_TAG = %[
      pubkey ${tag}
      bindaddr tcp://*:5556
  ]

  def create_driver(conf = CONFIG)
    Fluent::Test::Driver::Output.new(Fluent::Plugin::ZmqPubOutput).configure(conf)
  end

  def test_configure
    d = create_driver

    assert_equal '${tag}:${key1}', d.instance.pubkey
    assert_equal 'tcp://*:5556', d.instance.bindaddr
  end

  def test_format
    d = create_driver

    time = Time.parse("2011-01-02 13:14:15 UTC").to_i
    d.run(default_tag: 'test') do
      d.feed(time, {"key1"=>"aaa"})
      d.feed(time, {"key1"=>"bbb", "key2"=>3})
    end

    assert_equal ["test",time.to_i,{ "key1" => "aaa"}].to_msgpack, d.formatted[0]
    assert_equal ["test",time.to_i,{ "key1" => "bbb", "key2" => 3}].to_msgpack, d.formatted[1]
  end

  def test_write
    config = Fluent::Config::Element.new('ROOT', '', {
                                           '@type' => 'zmq_pub',
                                           'pubkey' => '${tag}:${key1}',
                                           'bindaddr' => 'tcp://*:5556'
                                         }, [
                                           Fluent::Config::Element.new('buffer', 'tag,key1', {
                                                                         '@type' => 'memory',
                                                                       },[] )
                                         ])
    d = create_driver(config)
    @subscriber.setsockopt(ZMQ::SUBSCRIBE,"test:aaa")

    time = Time.parse("2011-01-02 13:14:15 UTC").to_i
    msg = ''
    d.run(default_tag: 'test', shutdown: false) do
      d.feed(time, {"key1"=>"aaa"})
      d.feed(time, {"key1"=>"bbb", "key2"=>3})
      d.feed(time, {"key1"=>"aaa", "key2"=>4})
    end

    sleep 1
    @subscriber.recv_string(msg,ZMQ::DONTWAIT)
    (key, record) = msg.split(" ",2)
    assert_equal ["test",time.to_i,{ "key1" => "aaa"}].to_msgpack, record

    msg = ''
    @subscriber.recv_string(msg,ZMQ::DONTWAIT)
    d.instance.shutdown # dispose
    (key, record) = msg.split(" ",2)
    assert_equal ["test",time.to_i,{ "key1" => "aaa","key2" => 4 }].to_msgpack, record

  end

  def test_write_bulk
    config_bulk = Fluent::Config::Element.new('ROOT', '', {
                                                '@type' => 'zmq_pub',
                                                'pubkey' => '${tag}:${key1}',
                                                'bindaddr' => 'tcp://*:5556'
                                              }, [
                                                Fluent::Config::Element.new('buffer', 'tag,key1', {
                                                                              '@type' => 'memory',
                                                                            },[] )
                                              ])
    d = create_driver(config_bulk)
    @subscriber.setsockopt(ZMQ::SUBSCRIBE,"test:aaa")

    time = Time.parse("2011-01-02 13:14:15 UTC").to_i
    msg = ''
    d.run(default_tag: 'test', shutdown: false) do
      d.feed(time, {"key1"=>"aaa"})
      d.feed(time, {"key1"=>"bbb", "key2"=>3})
      d.feed(time, {"key1"=>"aaa", "key2"=>4})
    end

    sleep 1
    @subscriber.recv_string(msg,ZMQ::DONTWAIT)
    d.instance.shutdown # dispose
    (key, record) = msg.split(" ",2)
    assert_equal ["test",time.to_i,{ "key1" => "aaa"}].to_msgpack, record

    msg = ''
    @subscriber.recv_string(msg,ZMQ::DONTWAIT)
    (key, record) = msg.split(" ",2)
    assert_equal ["test",time.to_i,{ "key1" => "aaa","key2" => 4 }].to_msgpack, record

  end


end
