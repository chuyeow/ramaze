module Ramaze
  class ConcurrentState
    def initialize
      decide
    end

    def decide
      require 'fiber'
      @state = Ramaze::Fiber
    rescue LoadError
      Log.warn('Cannot use Fiber, fall back to threading')
      @state = Thread
    end

    def [](key)
      @state[key]
    end

    def []=(key, value)
      @state[key] = value
    end
  end
end
