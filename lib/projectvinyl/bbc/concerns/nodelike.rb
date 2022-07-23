module ProjectVinyl
  module Bbc
    module Nodelike
      URL_HANDLING_TAGS = %w[a url img embed].freeze
      SELF_CLOSING_TAGS = %w[br hr link meta input].freeze

      def inner_text=(text)
        @children = []
        self.append_text(text)
      end

      def inner_text
        inner(:text)
      end

      def inner_html
        inner(:html)
      end

      def inner_bbc
        inner(:bbc)
      end

      def outer_html
        outer(:html)
      end

      def outer_bbc
        outer(:bbc)
      end

      def even
        depth % 2 == 0
      end

      def self_closed?
        SELF_CLOSING_TAGS.include?(tag_name)
      end

      def handles_urls?
        URL_HANDLING_TAGS.include?(tag_name)
      end

      def to_json
        { html: outer_html, bbc: outer_bbc }
      end
    end
  end
end
