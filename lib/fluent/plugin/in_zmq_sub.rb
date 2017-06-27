require 'fluent/input'

module Fluent

  class ZmqSubInput < Fluent::Input
    Fluent::Plugin.register_input('zmq_sub', self)

    config_param :subkey, :string, :default => ""
    config_param :publisher, :string, :default => "tcp://127.0.0.1:5556"
    config_param :bulk_send, :bool, :default => false

    attr_reader :subkeys

    def initialize
      super
      require 'ffi-rzmq'
    end

    def configure(conf)
      super
      @subkeys = @subkey.split(",")
    end

    def start
      super
      @context =ZMQ::Context.new()
      @thread = Thread.new(&method(:run))
    end

    def shutdown
      super
      Thread.kill(@thread)
      @thread.join
      @context.terminate
    end

    def run
      begin
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
              records = MessagePack.unpack(records)
              if @bulk_send && records[0].class == Array
                es = MultiEventStream.new
                prev_tag = nil
                records.each do |tag, time, record|
                  if prev_tag && prev_tag != tag
                    Engine.emit_stream(prev_tag, es)
                    es = MultiEventStream.new
                  end
                  es.add(time, record)
                  prev_tag = tag
                end
                Engine.emit_stream(prev_tag, es) if es.to_a.size > 0
              else
                Engine.emit(*records)
              end
            rescue => e
              log.warn "Error in processing message.",:error_class => e.class, :error => e
              log.warn_backtrace
            end
            msg = ''
          end
          sleep(0.1)
        end
      rescue => e
        log.error "error occurred while executing plugin.", :error_class => e.class, :error => e
        log.warn_backtrace
      ensure
        if @subscriber
          @subscriber.close
        end
      end
    end

  end

end
