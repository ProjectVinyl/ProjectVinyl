require 'projectvinyl/bbc/tag_generator'

module ProjectVinyl
  module Bbc
    module Traversable
      attr_reader :children

      def traverse(&block)
        block.call(self)
        children.each do |child|
          child.traverse(&block) if child.respond_to? :traverse
        end
      end

      def getElementsByTagName(name)
        results = []
        traverse{|c| results << c if c.tag_name == name }
        results
      end

      def inner_text=(text)
        @children = []
        self.append_text(text)
      end

      def append_node(name = '')
        __append_child(Node.new(self, name))
      end

      def append_text(text)
        if text.length > 0
          if children.length > 0 && children.last.text_node?
            children.last.append_text(text)
          else
            __append_child(TextNode.new(text))
          end
        end

        self
      end

      def inner(type)
        return '' if tag_name == 'script' || tag_name == 'style'
        ans = (children.map {|child|child.outer(type)}).join
        return ans if type != :html
        ans.strip.gsub(/\n/, '<br>')
      end

      def outer(type)
        return '' if tag_name == 'script' || tag_name == 'style'
        return inner_text if type == :text
        if type == :raw
          html = "<#{tag_name}"
          if respond_to?(:classes) && respond_to?(:attributes)
            attributes[:class] = classes.join(' ') if !classes.empty?
            html += attributes.to_html
          end
          return html + ' />' if self_closed?
          html += ">#{inner(type)}"
          html += "</#{tag_name}>"
          return html
        end
        TagGenerator.generate(self, type)
      end

      private
      def __append_child(node)
        children << node

        node
      end
    end
  end
end