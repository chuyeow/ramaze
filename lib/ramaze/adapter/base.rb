#          Copyright (c) 2008 Michael Fellinger m.fellinger@gmail.com
# All files in this distribution are subject to the terms of the Ruby license.

module Ramaze
  module Adapter

    # Helper to assign a new block to before_call
    # Usage:
    #   Ramaze::Adapter.before do |env|
    #     if env['PATH_INFO'] =~ /suerpfast/
    #       [200, {'Content-Type' => 'text/plain'}, ['super fast!']]
    #     end
    #   end

    def self.before(&block)
      @before = block if block
      @before
    end

    # This class is holding common behaviour for its subclasses.

    class Base
      class << self
        attr_reader :thread

        # For the specified host and for all given ports call run_server and
        # add the returned thread to the Global.adapters ThreadGroup.
        # Afterwards adds a trap for the value of Global.shutdown_trap which
        # calls Ramaze.shutdown when triggered (usually by SIGINT).

        def start(host = nil, port = nil)
          @thread = startup(host, port)
          Global.server = self

          trap(Global.shutdown_trap){
            trap(Global.shutdown_trap){ exit!  }
            exit
          }
        end

        # Does nothing by default

        def shutdown
          if @server.respond_to?(:stop)
            Log.dev "Stopping @server"
            @server.stop
          else
            Log.dev "Cannot stop @server, skipping this step."
          end
        end

        def join
          @thread.join
        end

        def call(env)
          Dispatcher.call(env)
        end
      end
    end
  end
end
