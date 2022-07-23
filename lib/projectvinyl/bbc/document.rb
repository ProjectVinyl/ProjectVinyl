require 'projectvinyl/bbc/tag_generator'
require 'projectvinyl/bbc/text_node'
require 'projectvinyl/bbc/concerns/nodelike'
require 'projectvinyl/bbc/concerns/traversable'
require 'projectvinyl/bbc/concerns/resolvable'

module ProjectVinyl
  module Bbc
    class Document
      include Nodelike
      include Traversable
      include Resolvable

      attr_reader :tag_name

      def initialize
        @tag_name = 'Document'
        @children = []
      end

      def set_resolver(&block)
        @resolver = block
      end

      def text_node?
        false
      end

      def depth
        0
      end

      def closing?(content, index, open, close)
        tag = "#{open}/#{tag_name}#{close}"
        return [true, tag.length] if content.index(tag) == index
        [false, 0]
      end

      def to_s
        "DOCUMENT({#{children}})"
      end

      def inspect
        "DOCUMENT{#{children}}"
      end
    end
  end
end
