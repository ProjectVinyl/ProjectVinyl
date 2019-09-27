module ProjectVinyl
  module Storage
    class BaseVideoFile

      def special_name
        if @parent.names.key?(@key) && @parent.names[@key] != @key
          return @parent.names[@key]
        end
        ''
      end

      def stack_size
        0
      end

      def each
      end

      def commit
        @saved = true
        @parent.items << self
      end

      def consume(item)
      end

      def ref
        @raw
      end

      protected

      def raw=(item)
        @raw = item
        @key = item.split(/\.|-/)[0]
      end
    end
  end
end
