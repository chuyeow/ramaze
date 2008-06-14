require 'ramaze/current/request'
require 'ramaze/current/response'
require 'ramaze/current/session'

require 'ramaze/chain/rewrite'
require 'ramaze/chain/dynamic'
require 'ramaze/chain/route'

module Ramaze
  class Current
    CHAIN = Chain.new(Chain::Rewrite, Chain::Dynamic, Chain::Route)

    def self.call(env, chain = CHAIN)
      new(env).call(chain)
    end

    attr_reader :request, :response

    def initialize(env)
      @request = Request.new(env)
      @response = Response.new
    end

    def call(chain)
      path = request.path_info.squeeze('/')
      chain.context = self

      if response = chain.call(path)
        @response = response
      end

      finish
    end

    def finish
      response.finish
    end
  end
end

__END__


    CHAIN = OrderedSet.new(
      Chain::Rewrite,
      # Chain::Static,
      Chain::Dynamic,
      Chain::Route
    )

    class << self
      include Trinity

      def call(env)
        setup(env)
        chain
        finish
      end

      def setup(env)
        self.request = Request.new(env)
        self.response = Response.new
        self.session = Session.new
      end

      def chain
        chain = Chain.new(CHAIN)
        catch :respond do
          chain.call request.path_info.squeeze('/')
        end
      end

      def finish
        session.finish if session
        response.finish
      end
    end
  end
end
