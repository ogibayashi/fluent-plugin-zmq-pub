require 'fluent/plugin/output'

module Fluent::Plugin
  class ZmqPubOutput < Output
    Fluent::Plugin.register_output('zmq_pub', self)

    DEFAULT_BUFFER_TYPE = "memory"

    config_param :pubkey, :string
    config_param :bindaddr, :string, :default => 'tcp://*:5556'
    config_param :highwatermark, :integer, :default => 1000
    # Send multiple record with the same publish key at once
    config_param :bulk_send, :bool, :default => false

    config_section :buffer do
      config_set_default :@type, DEFAULT_BUFFER_TYPE
      config_set_default :chunk_keys, ['tag']
    end

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

    def formatted_to_msgpack_binary?
      true
    end

    def write(chunk)
      records = { }
      #  to_msgpack in format, unpack in write, then to_msgpack again... better way?
      pubkey_replaced = extract_placeholders(@pubkey, chunk.metadata)
      chunk.msgpack_each{ |record|
        if @bulk_send
          records[pubkey_replaced] ||= []
          records[pubkey_replaced] << record
        else
          @mutex.synchronize {
            @publisher.send_string(pubkey_replaced + " " + record.to_msgpack,ZMQ::DONTWAIT)
          }
        end
      }
      if @bulk_send
        @mutex.synchronize {
          records.each{  |k,v|
            @publisher.send_string(k + " " + v.to_msgpack,ZMQ::DONTWAIT)
          }
        }
      end

    end

    def shutdown
      @publisher.close
      @context.terminate
      super
    end

  end

end
