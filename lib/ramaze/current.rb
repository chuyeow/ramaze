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

    attr_reader :request, :response, :session
    attr_accessor :action, :controller

    def initialize(env)
      @request = Request.new(env)
      @response = Response.new
      @session = Session.new(self)
      @state = {}
    end

    def call(chain)
      path = request.path_info.squeeze('/')
      chain.context = self

      respond = redirect = nil

      respond = catch(:respond){
        redirect = catch(:redirect){
          r = chain.call(path)
          pp :r => r
          @response = r if r
          throw(:respond)
        }
        response.build(*redirect)
      }

      pp :respond => respond
      pp :redirect => redirect
      pp :response => response

      # catch(:respond){
      #   redirected = catch(:redirect){
      #     filter(path)
      #     throw(:respond)
      #   }
      #   response.build(*redirected)
      # }

      # if response = chain.call(path)
      #   @response = response
      # end

      finish
    end

    def finish
      session.finish if session
      response.finish
    end

    def [](key)
      @state[key]
    end

    def []=(key, value)
      @state[key] = value
    end
  end
end
