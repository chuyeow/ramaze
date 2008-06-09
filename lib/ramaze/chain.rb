require 'enumerator'

# require 'chain/directory'
# require 'chain/error'
# require 'chain/static'

module Ramaze
  class Chain
    include Trinity

    attr_reader :original_links, :links, :link, :state

    # Backwards compatible with 1.8.x
    # For ruby >=1.8.7 a simple links.flatten.each would be enough.
    def initialize(*links)
      @original_links = links.flatten
      @state = {}
      rewind
    end

    # May raise StopIteration when no elements are left.
    def call(*args)
      @args = args # store for #next

      while @link = links.shift
        if r = link.call(self, *args)
          @r = r
        end
      end
    rescue StopIteration => ex
      @r
    end

    def next
      call(*@args)
    end

    def rewind
      @links = @original_links.dup
      @link = nil
    end

    def log(path = request.request_uri, from = @link)
      name = from.to_s.split('::').last
      message = "%8s from: %-15s to: %s" % [name, request.ip, path]

      case path
      when *Global.boring
        Log.dev message
      else
        Log.info message
      end
    rescue => ex
      Log.error ex
    end
  end
end
