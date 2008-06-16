module Ramaze
  class Fiber < ::Fiber
    def initialize
      @state = {}
    end

    def [](key)
      @state[key]
    end

    def []=(key, value)
      @state[key] = value
    end

    def self.[](key)
      current[key]
    end

    def self.[]=(key, value)
      current[key] = value
    end
  end if defined?(::Fiber)
end
