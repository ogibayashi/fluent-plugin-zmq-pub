require 'fluent/plugin/input'

module Fluent::Plugin

  class ZmqSubInput < Input
    Fluent::Plugin.register_input('zmq_sub', self)

    helpers :thread

    config_param :subkey, :array, :default => []
    config_param :publisher, :string, :default => "tcp://127.0.0.1:5556"
    config_param :bulk_send, :bool, :default => false

    attr_reader :subkeys

    def initialize
      super
      require 'ffi-rzmq'
    end

    def configure(conf)
      super
      @subkeys = @subkey # for compatibility.
      @unpacker = Fluent::Engine.msgpack_factory.unpacker
    end

    def start
      super
      @context =ZMQ::Context.new()
      thread_create(:in_zmq_sub_runner, &method(:run))
    end

    def shutdown
      if @subscriber
        @subscriber.close
      end

      @context.terminate
      super
    end

    def run
      @subscriber = @context.socket(ZMQ::SUB)
      @subscriber.connect(@publisher)
      if @subkeys.size > 0
        @subkeys.each do |k|
          @subscriber.setsockopt(ZMQ::SUBSCRIBE,k)
        end
      else
        @subscriber.setsockopt(ZMQ::SUBSCRIBE,'')
      end
      loop do
        msg = ''
        while @subscriber.recv_string(msg,ZMQ::DONTWAIT) && msg.size > 0
          begin
            (key, records) = msg.split(" ",2)
            @unpacker.feed_each(records) do |obj|
              if @bulk_send && obj[0].class == Array
                es = Fluent::MultiEventStream.new
                prev_tag = nil
                obj.each do |tag, time, record|
                  if prev_tag && prev_tag != tag
                    router.emit_stream(prev_tag, es)
                    es = Fluent::MultiEventStream.new
                  end
                  es.add(time, record)
                  prev_tag = tag
                end
                router.emit_stream(prev_tag, es) if es.to_a.size > 0
              else
                router.emit(*obj)
              end
            end
          rescue => e
            log.warn "Error in processing message.",:error_class => e.class, :error => e
            log.warn_backtrace
          end
          msg = ''
        end
        sleep(0.1)
      end
    end

  end

end
