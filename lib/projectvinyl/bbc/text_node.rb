require 'projectvinyl/bbc/concerns/nodelike'

module ProjectVinyl
  module Bbc
    class TextNode
      include Nodelike

      def self.truncate_link(url)
        url = url.gsub(/^(http[s]*:)*[\/]+/, '')
        return url[0...22] + '...' if url.length > 25
        url
      end

      def initialize(text)
        @inner_text = text
      end

      def append_text(text)
        @inner_text += text
      end

      def getElementsByTagName(name)
        []
      end

      def text_node?
        true
      end

      def inner(type)
        outer(type)
      end

      def outer(type)
        CGI::escapeHTML CGI.unescapeHTML(@inner_text)
      end

      def depth
        0
      end
    end
  end
end
