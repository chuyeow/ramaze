#          Copyright (c) 2008 Michael Fellinger m.fellinger@gmail.com
# All files in this distribution are subject to the terms of the Ruby license.

require 'ramaze/route'
require 'ramaze/middleware'
require 'ramaze/chain'
require 'ramaze/current'

module Ramaze
  module Dispatcher
    MIDDLEWARE = OrderedSet.new(
      # Rack::CommonLogger,
      Rack::ShowExceptions,
      Rack::ShowStatus
      # MiddleWare::Benchmark
    )

    CASCADE = [
      MiddleWare::Record,
      MiddleWare::Directory,
      Current
    ]

    def self.call(env)
      Rack::Builder.new{
        MIDDLEWARE.each{|mw| use(mw) }

        run Rack::Cascade.new(CASCADE)
      }.call(env)
    end
  end
end
