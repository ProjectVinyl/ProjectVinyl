module ProjectVinyl
  module Bbc
    module Resolvable
      def resolver(trace, fallback)
        trace << tag_name.to_sym if !trace.include?(tag_name.to_sym)
        return fallback if @parent.nil?
        @parent.resolver(trace, fallback)
      end

      def resolve_dynamically(&fallback)
        trace = []
        resolver(trace, fallback).call(trace, tag_name.to_sym, self, fallback)
      end
    end
  end
end