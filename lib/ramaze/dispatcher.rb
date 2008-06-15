#          Copyright (c) 2008 Michael Fellinger m.fellinger@gmail.com
# All files in this distribution are subject to the terms of the Ruby license.

require 'ramaze/route'
require 'ramaze/middleware'
require 'ramaze/chain'
require 'ramaze/current'

module Ramaze
  module Dispatcher
    MIDDLEWARE = OrderedSet.new(
      Rack::CommonLogger,
      Rack::ShowExceptions,
      Rack::ShowStatus,
      MiddleWare::Reloader
      # MiddleWare::Directory
      # MiddleWare::Benchmark
    )

    CASCADE = OrderedSet.new(MiddleWare::File, Current)

    @hash = nil # [@middleware, @cascade]

    # This make sure there is only one builder and it's instantiated anew when
    # middleware or cascade change.
    def self.call(env)
      mw, ca = MIDDLEWARE, CASCADE

      unless @hash == [mw, ca]
        # FIXME: empty block due to bug in rack
        @builder = Rack::Builder.new{}

        mw.each{|m| @builder.use(m) }
        @builder.run(Rack::Cascade.new(ca))
        @hash = [mw, ca]
      end

      @builder.call(env)
    end
  end
end
