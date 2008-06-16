module Ramaze
  class Thread < ::Thread
    def self.[](key)
      current[key]
    end

    def self.[]=(key, value)
      current[key] = value
    end
  end
end

