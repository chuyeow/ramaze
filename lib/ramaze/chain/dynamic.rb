#          Copyright (c) 2008 Michael Fellinger m.fellinger@gmail.com
# All files in this distribution are subject to the terms of the Ruby license.

require 'ramaze/resolve'

module Ramaze
  class Chain

    # This dispatcher is responsible for relaying requests to Controller::handle
    # and filtering the results using FILTER.

    class Dynamic
      def self.call(chain, path)
        p :Dynamic => path
        response = chain.response
        body = Resolver.new(chain.context).handle(path)
        pp :body => body
        response.body << body
        chain.next
        response
      end
    end
  end
end
