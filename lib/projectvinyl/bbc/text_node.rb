module ProjectVinyl
  module Bbc
    class TextNode
      def initialize(text)
        @inner_text = text
      end
      
      def inner_text
        CGI::escapeHTML @inner_text
      end
      
      def inner(type)
        outer(type)
      end
      
      def outer(type)
        inner_text
      end
      
      def outer_html
        outer(:html)
      end
      
      def outer_bbc
        outer(:bbc)
      end
    end
  end
end