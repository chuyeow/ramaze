module Ramaze
  class Chain
    module Route
      def self.call(chain, path)
        if chain.state[:route] == path
          chain.next
        else
          chain.state[:route] = path

          if new_path = Ramaze::Route.resolve(path)
            Log.dev("Routing `#{path}' to `#{new_path}'")
            path = new_path
            chain.rewind
          end
        end

        chain.next(path)
      end
    end
  end
end
