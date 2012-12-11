module Fluent
  class Fluent::ZmqPubOutput < Fluent::BufferedOutput
    Fluent::Plugin.register_output('zmq_pub', self)

    config_param :pubkey, :string
    config_param :bindaddr, :string

    def initialize
      super
      require 'zmq'
    end

    def configure(conf)
      super
    end
    
    def start
      super
      @context = ZMQ::Context.new(1)
      @publisher = @context.socket(ZMQ::PUB)
      @publisher.bind(@bindaddr)
    end

    def format(tag, time, record)
      [tag,time,record].to_msgpack
    end

    def write(chunk)
      records = []
      chunk.msgpack_each{ |record|
        pubkey_replaced = @pubkey.gsub(/<%(.+?)%>/){ |match|
          if $1 == "tag"
            record[0]
          else
            record[2][$1]
          end
        }
        #  to_msgpack in format, unpack in write, then to_msgpack again... better way?
        @publisher.send(pubkey_replaced + " " + record.to_msgpack)
      }
      
    end
 
    def shutdown
      super
      @publisher.close
      @context.close
    end

  end

end
