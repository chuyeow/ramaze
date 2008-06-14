module Ramaze

  # ctx = 'Context'
  # l1 = lambda{|c, path| c.yield('/bar') }
  # l2 = lambda{|c, path| c.yield('/foo') }
  # l3 = lambda{|c, path| [200, path] }
  #
  # chain = Ramaze::Chain.new(ctx, l1, l2, l3)
  # p chain.call('/')

  class Chain
    attr_accessor :context, :index, :link, :links, :state

    def initialize(context, *links)
      @context = context
      @links = links
      @state = {}
      @result = nil
      rewind
    end

    def call(*args)
      @args = args

      if link = links[index]
        self.index += 1
        @result = link.call(self, *args)
      end

      return @result
    rescue ArgumentError => error
      raise ArgumentError, "in chain #{link}: #{error}", error.backtrace
    end

    def next(*args)
      args = @args if args.empty?
      call(*args)
    end

    def rewind
      self.index = 0
    end

    def finish(result = @result)
      @result = result
      self.index = links.size
      @result
    end

    def response
      context.response
    end

    def request
      context.request
    end
  end
end

__END__

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
