require 'ramaze/current/request'
require 'ramaze/current/response'
require 'ramaze/current/session'

require 'ramaze/chain/rewrite'
require 'ramaze/chain/dynamic'
require 'ramaze/chain/route'

module Ramaze
  class Current
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
