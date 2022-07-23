require 'projectvinyl/bbc/tag_generator'
require 'projectvinyl/bbc/text_node'
require 'projectvinyl/bbc/attributes'
require 'projectvinyl/bbc/concerns/nodelike'
require 'projectvinyl/bbc/concerns/traversable'
require 'projectvinyl/bbc/concerns/resolvable'

module ProjectVinyl
  module Bbc
    class Node
      include Nodelike
      include Traversable
      include Resolvable

      attr_reader :equals_par
      attr_reader :tag_name
      attr_reader :parent
      attr_reader :classes
      attr_reader :attributes

      def initialize(parent, name = '')
        @tag_name = name
        @children = []
        @attributes = Attributes.new
        @classes = []
        @parent = parent
      end

      def equals_par=(par)
        @equals_par = par
      end

      def set_attribute(name, value)
        name = name.strip.underscore.to_sym
        @attributes[name] = value
        @classes = value.split(/\s/) if name == :class

        self
      end

      def text_node?
        false
      end

      def depth
        return 0 if parent.nil?
        parent.depth + 1
      end

      def closing?(content, index, open, close)
        tag = "#{open}/#{tag_name}#{close}"
        return [true, tag.length] if content.index(tag) == index
        if !parent.nil?
          p = parent.closing?(content, index, open, close)
          return [p[0], 0]
        end
        [false, 0]
      end
    end
  end
end