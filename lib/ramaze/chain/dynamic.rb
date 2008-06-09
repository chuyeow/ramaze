#          Copyright (c) 2008 Michael Fellinger m.fellinger@gmail.com
# All files in this distribution are subject to the terms of the Ruby license.

module Ramaze
  class Chain

    # This dispatcher is responsible for relaying requests to Controller::handle
    # and filtering the results using FILTER.

    class Dynamic
      extend Trinity

      def self.call(chain, path)
        chain.log

        catch :respond do
          body = Controller.handle(path)
          response.build(body)
        end

        chain.next

        response
      end
    end
  end
end
