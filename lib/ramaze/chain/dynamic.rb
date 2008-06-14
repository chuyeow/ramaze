#          Copyright (c) 2008 Michael Fellinger m.fellinger@gmail.com
# All files in this distribution are subject to the terms of the Ruby license.

module Ramaze
  class Chain

    # This dispatcher is responsible for relaying requests to Controller::handle
    # and filtering the results using FILTER.

    class Dynamic
      def self.call(chain, path)
        request = chain.request
        response = chain.response

        response.body = 'Hello, World!'
        response.status = 200
        chain.finish(response)
      end
    end
  end
end

__END__
        response = chain.response
        # chain.log

        catch :respond do
          body = Controller.handle(path)
          response.build(body)
        end

        p response

        chain.next

        response
      end
    end
  end
end
