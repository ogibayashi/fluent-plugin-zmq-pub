require 'helper'
require 'ffi-rzmq'

class ZmqSubIutputTest < Test::Unit::TestCase
  def setup
    Fluent::Test.setup
    @context = ZMQ::Context.new()
    @publisher = @context.socket(ZMQ::PUB)
    @publisher.bind("tcp://*:5556")
  end
  
  def teardown
    @publisher.close
    @context.terminate
  end

  PUBLISHER = "tcp://127.0.0.1:5556"
  CONFIG = %[
     publisher #{PUBLISHER}
     subkey test1.,test2.
  ]
  
  
  def create_driver(conf=CONFIG)
    Fluent::Test::InputTestDriver.new(Fluent::ZmqSubInput).configure(conf)
  end
  
  def test_configure
    d = create_driver(CONFIG + "bulk_send true")
    assert_equal PUBLISHER, d.instance.publisher
    assert_equal ["test1.","test2."], d.instance.subkeys
    assert_equal true, d.instance.bulk_send
  end
  
  def test_receive
    d = create_driver
    
    time = Time.parse("2011-01-02 13:14:15 UTC").to_i
    Fluent::Engine.now = time
    
    d.expect_emit "test1.aa", time, {"a"=>1}
    d.expect_emit "test2.bb", time, {"a"=>2}
    
    d.run do
      d.expected_emits.each {|tag,time,record|
        send_record("dummy",time,record)  # This record should not be received.
        send_record(tag,time,record)
      }
      sleep 1
    end
  end

  def test_no_subkey
    d = create_driver("")
    
    time = Time.parse("2011-01-02 13:14:15 UTC").to_i
    Fluent::Engine.now = time
    
    d.expect_emit "test1.aa", time, {"a"=>1}
    d.expect_emit "test2.bb", time, {"a"=>2}
    
    d.run do
      d.expected_emits.each {|tag,time,record|
        send_record(tag,time,record)
      }
      sleep 1
    end
  end


  def test_receive_bulk
    d = create_driver(CONFIG + "bulk_send true")
    
    time = Time.parse("2011-01-02 13:14:15 UTC").to_i
    Fluent::Engine.now = time
    
    d.expect_emit "test3.aa", time, {"a"=>1}
    d.expect_emit "test4.bb", time, {"a"=>2}
    
    d.run do
      record_to_send = []
      d.expected_emits.each {|tag,time,record|
        record_to_send << [tag,time,record]
      }
      send_record_bulk("test1.aa",record_to_send)
      sleep 1
    end
  end

  def send_record(tag,time,record)
    @publisher.send_string(tag + " " + [tag,time,record].to_msgpack)
  end

  def send_record_bulk(tag,records)
    @publisher.send_string(tag + " " + records.to_msgpack)
  end
end
