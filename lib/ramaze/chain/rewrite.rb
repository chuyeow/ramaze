module Ramaze
  class Chain
    module Rewrite
      def self.call(chain, path)
        if new_path = Ramaze::Rewrite.resolve(path)
          Log.dev("Rewriting `#{path}' to `#{new_path}'")
          path = new_path
        end

        chain.call(path)
      end
    end
  end
end
