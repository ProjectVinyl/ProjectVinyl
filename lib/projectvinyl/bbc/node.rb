require 'projectvinyl/bbc/tag_generator'
require 'projectvinyl/bbc/text_node'

module ProjectVinyl
  module Bbc
    class Node
      URL_HANDLING_TAGS = %w[a url img].freeze

      def initialize(parent, name = '')
        @tag_name = name
        @children = []
        @attributes = Hash.new do
          ""
        end
        @classes = []
        @parent = parent
      end

      attr_reader :equals_par
      attr_reader :tag_name
      attr_reader :parent
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

        if @tag_name == name
          results << self
        end

        results
      end

      def append_node(name = '')
        tag = Node.new(self, name)
        @children << tag
        return tag
      end

      def append_text(text)
        if text.length > 0
          @children << TextNode.new(text)
        end
      end

      def tag_name=(tag)
        @tag_name = tag.split('=')[0].strip
        if @tag_name.gsub(/[^a-zA-Z0-9]/, '') != @tag_name
          @tag_name = ''
        end
      end

      def equals_par=(par)
        @equals_par = par
      end

      def set_attribute(name, value)
        name = name.strip.underscore.to_sym
        @attributes[name] = value
        if name == :class
          @classes = value.split(/\s/)
        end

        self
      end

      def inner(type)
        ans = (@children.map {|child|child.outer(type)}).join
        if type != :html
          return ans
        end
        ans.strip.gsub(/\n/, '<br>')
      end

      def outer(type)
        if type == :text
          return inner_text
        end
        TagGenerator.generate(self, type)
      end

      def set_resolver(&block)
        @resolver = block
      end

      def resolver(trace, fallback)
        if !trace.include?(tag_name.to_sym)
          trace << tag_name.to_sym
        end
        if !@resolver.nil?
          return @resolver
        end

        if @parent.nil?
          return fallback
        end

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

      def self_closed?
        tag_name == 'br'
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