module ProjectVinyl
  module Web
    class TextNode
      def initialize(text)
        @innerHTML = text
      end
      
      attr_reader :innerHTML
      
      def innerText
        @innerHTML
      end
      
      def innerText=(text)
        @innerHTML = text
      end
      
      def id
        ""
      end
      
      def classes
        []
      end
      
      def attributes
        {}
      end
      
      def children
        classes
      end
      
      def getElementById(_d)
        nil
      end
      
      def getElementsByTagName(_tagName)
        []
      end
      
      def getElementsByClassName(_className)
        []
      end
      
      def to_s
        @innerHTML
      end
      
      def to_bbc
        @innerHTML
      end
    end
  end
end