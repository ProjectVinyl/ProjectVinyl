require 'projectvinyl/web/text_node'

module ProjectVinyl
  module Web
    class HTMNode
      attr_reader :tagName
      attr_reader :children
      attr_reader :attributes
      
      def self.Parse(content)
        result = HTMNode.new
        content = result.parse(content)
        result.children << TextNode.new(content) if content.present?
        result
      end
      
      def self.extract_uri_parameter(url, parameter)
        URI.unescape(url.split("#{parameter}=").last.split('&').first)
      end
      
      def initialize
        @attributes = {}
        @children = []
      end
      
      def id
        @attributes[:id] || ""
      end
      
      def classes
        (@attributes[:class] || "").split(' ')
      end
      
      def innerHTML
        result = ''
        @children.each do |i|
          result << i.to_s
        end
        result
      end
      
      def innerBBC
        result = ''
        @children.each do |i|
          result << i.to_bbc
        end
        result
      end
      
      def innerText
        return '\n' if @tagName == 'br'
        result = ''
        @children.each do |i|
          result << i.innerText
        end
        result
      end
      
      def innerText=(text)
        @children = []
        @children << TextNode.new(text)
      end
      
      def getElementById(d)
        return self if self.id == d
        @children.each do |i|
          result = i.getElementById(d)
          return result if result
        end
        nil
      end
      
      def getElementsByTagName(tagName)
        results = []
        results << self if tagName == @tagName
        @children.each do |i|
          results += i.getElementsByTagName(tagName)
        end
        results
      end
      
      def getElementsByClassName(className)
        result = []
        result << self if classes.index(className)
        @children.each do |i|
          result += i.getElementsByClassName(className)
        end
        result
      end
      
      def loadAttr(content)
        index = -1
        quote = nil
        name = ''
        value = ''
        inValue = false
        while index < content.length - 1
          index += 1
          if !inValue || quote.nil?
            if content[index] == '/' && index < content.length - 1 && content[index + 1] == '>'
              return content[index..content.length]
            end
            if content[index] == '>'
              @attributes[name.strip] = value if !name.empty?
              return content[(index + 1)..content.length]
            end
          end
          if !inValue
            if content[index] == '='
              inValue = true
              next
            end
            name += content[index]
          else
            if quote.nil?
              if content[index] == '"' || content[index] == "'"
                quote = content[index]
                next
              elsif content[index] == ' '
                @attributes[name.strip] = value
                name = ''
                value = ''
                inValue = false
                next
              end
            else
              if content[index] == quote
                quote = nil
                @attributes[name.strip] = value
                name = ''
                value = ''
                inValue = false
                next
              end
            end
            value += content[index]
          end
        end
        content[(index + 1)..content.length]
      end
      
      def parse(content)
        index = -1
        inNode = false
        inContent = false
        tagName = ''
        text = ''
        while index < content.length - 1
          index += 1
          if inContent
            if @tagName == 'br' || @tagName == 'img'
              index += 1 if content[index] == '/'
              index += 1 if content[index] == '>'
              return content[index..content.length]
            end
            return content[3..content.length] if content.index('/>') == 0
            if content.index('</' + @tagName + '>') == index
              @children << TextNode.new(text) if !text.empty?
              return content[(index + ('</' + @tagName + '>').length)..content.length]
            end
            if content.index('<') == index
              if !text.empty?
                @children << TextNode.new(text)
                text = ''
              end
              child = HTMNode.new
              content = child.parse(content)
              @children << child
              index = -1
              next
            end
            text += content[index]
          end
          if inNode
            if content[index] == ' '
              @tagName = tagName.strip
              content = self.loadAttr(content[(index + 1)..content.length])
              index = -1
              inNode = false
              inContent = true
              next
            elsif content[index] == '>' || content[index] == '/'
              next if tagName.empty?
              @tagName = tagName
              inContent = true
              inNode = false
              content = content[(index + 1)..content.length]
              index = -1
              next
            else
              tagName += content[index]
              next
            end
          end
          if content[index] == '<'
            inNode = true
            next
          end
        end
        @children << TextNode.new(text) if !text.empty?
        content[(index + 1)..content.length]
      end
      
      def to_s
        "<" + @tagName + " " + @attributes.to_s + ">" + self.innerHTML + "</" + @tagName + ">"
      end
      
      def to_bbc
        return "\n" if @tagName == 'br'
        if @tagName == 'a'
          return "[url=" + @attributes['href'] + "]" + self.innerBBC + "[/url]"
        end
        return "[img]" + @attributes['src'] + "[/img]" if @tagName == 'img'
        tagName = @tagName
        tagName = 'q' if tagName == 'blockquote'
        "[" + tagName + "]" + self.innerBBC + "[/" + tagName + "]"
      end
    end
  end
end
