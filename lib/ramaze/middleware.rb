require 'benchmark'

module Ramaze
  module MiddleWare
    class File < ::Rack::File
      # def initialize(root)
      def initialize(app = nil)
        super Global.public_root
      end
    end

    class Directory < ::Rack::Directory
      def self.call(env)
        new(Global.public_root).call(env)
      end
    end

    class Record
      HISTORY = []

      def self.call(env)
        if filter = Global.record
          HISTORY << env if filter[env]
        end

        404
      end
    end

    class Benchmark
      def initialize(app)
        @app = app
      end

      def call(env)
        answer = nil
        time = ::Benchmark.measure{ answer = @app.call(env) }
        Log.debug('request took %.5fs [~%.0f r/s]' % [time.real, 1.0/time.real])
        answer
      end
    end
  end
end
