require 'projectvinyl/bbc/tag_generator'
require 'projectvinyl/bbc/text_node'
require 'projectvinyl/bbc/attributes'

module ProjectVinyl
  module Bbc
    class Node
      URL_HANDLING_TAGS = %w[a url img embed].freeze

      def initialize(parent, name = '')
        @tag_name = name
        @children = []
        @attributes = Attributes.new
        @classes = []
        @parent = parent
      end

      attr_reader :equals_par
      attr_reader :tag_name
      attr_reader :parent
      attr_accessor :next
      attr_reader :classes
      attr_reader :attributes
      attr_reader :children

      def inner_text=(text)
        @children = []
        self.append_text(text)
      end

      def getElementsByTagName(name)
        results = []

        @children.each do |c|
          results += c.getElementsByTagName(name)
        end

        results << self if @tag_name == name

        results
      end

      def append_node(name = '')
        __append_child(Node.new(self, name))
      end

      def append_text(text)
        if text.length > 0
          if @children.length > 0 && @children.last.text_node?
            @children.last.append_text(text)
          else
            __append_child(TextNode.new(text))
          end
        end

        self
      end

      def tag_name=(tag)
        @tag_name = tag.split('=')[0].strip
        @tag_name = '' if @tag_name.gsub(/[^a-zA-Z0-9]/, '') != @tag_name
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

      def inner(type)
        ans = (@children.map {|child|child.outer(type)}).join
        return ans if type != :html
        ans.strip.gsub(/\n/, '<br>')
      end

      def outer(type)
        return inner_text if type == :text
        TagGenerator.generate(self, type)
      end

      def set_resolver(&block)
        @resolver = block
      end

      def resolver(trace, fallback)
        trace << tag_name.to_sym if !trace.include?(tag_name.to_sym)

        return @resolver if !@resolver.nil?

        return fallback if @parent.nil?

        @parent.resolver(trace, fallback)
      end

      def resolve_dynamically(&fallback)
        trace = []
        resolver(trace, fallback).call(trace, self.tag_name.to_sym, self, fallback)
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

      def depth
        if @parent.nil?
          return 0
        end

        @parent.depth + 1
      end

      def even
        depth % 2 == 0
      end
      
      def text_node?
        false
      end

      def self_closed?
        tag_name == 'br'
      end

      def handles_urls?
        URL_HANDLING_TAGS.include?(tag_name)
      end

      def to_json
        { html: outer_html, bbc: outer_bbc }
      end
      
      private
      def __append_child(node)
        @children.last.next = node if @children.length > 0
        @children << node
        
        node
      end
    end
  end
end