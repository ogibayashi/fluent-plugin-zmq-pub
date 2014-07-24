module Fluent
  class Fluent::ZmqPubOutput < Fluent::BufferedOutput
    Fluent::Plugin.register_output('zmq_pub', self)

    config_param :pubkey, :string
    config_param :bindaddr, :string, :default => 'tcp://*:5556'
    config_param :highwatermark, :integer, :default => 1000

    def initialize
      super
      require 'ffi-rzmq'
      @mutex = Mutex.new
    end

    def configure(conf)
      super
    end
    
    def start
      super
      @context = ZMQ::Context.new()
      @publisher = @context.socket(ZMQ::PUB)
      @publisher.setsockopt(ZMQ::SNDHWM, @highwatermark)
      @publisher.bind(@bindaddr)
    end

    def format(tag, time, record)
      [tag,time,record].to_msgpack
    end

    def write(chunk)
      chunk.msgpack_each{ |record|
        pubkey_replaced = @pubkey.gsub(/\${(.*?)}/){ |s|
          case $1
          when 'tag'
            record[0]
          else
            record[2][$1]
          end
        }

        #  to_msgpack in format, unpack in write, then to_msgpack again... better way?
        @mutex.synchronize { 
          @publisher.send_string(pubkey_replaced + " " + record.to_msgpack,ZMQ::DONTWAIT)
        }
      }
    end
 
    def shutdown
      super
      @publisher.close
      @context.terminate
    end

  end

end
