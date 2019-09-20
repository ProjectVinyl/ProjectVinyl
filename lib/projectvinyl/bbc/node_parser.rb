require 'projectvinyl/bbc/emoticons'
require 'projectvinyl/bbc/node'

module ProjectVinyl
  module Bbc
    class NodeParser
      def self.parse(text, open, close)
        result = Node.new(nil, 'Document')
        NodeParser.new.parse(result, open + result.tag_name + close + text + open + '/' + result.tag_name + close, open, close)
        return result
      end
      
      def parse(node, content, open, close)
        index = -1
        state = -1
        name = ''
        text = ''
        quote = nil
        
        while (index < content.length - 1)
          index += 1
          
          if state == 1
            if node.tag_name == 'br' || node.tag_name == 'img'
              if content[index] == '/'
                index += 1
              end
              if content[index] == close
                index += 1
              end
              
              return content[index..content.length]
            end
            
            if content.index("/#{close}") == 0
              return content[3..content.length]
            end
            
            tag = "#{open}/#{node.tag_name}#{close}"
            
            if content.index(tag) == index
              node.append_text(text)
              return content[(index + tag.length)..content.length]
            end
            
            if content.index('&gt;&gt;') == index || content.index('>>') == index
              if text.length > 0
                node.append_text(text)
                text = ''
              end
              content = self.parse_reply_tag(node, content[index..content.length].sub(/&gt;&gt;|>>/,''))
              index = -1
              next
            end
            
            if result = self.parse_url(node, index, content, open, close)
                if text.length > 0
                  node.append_text(text)
                  text = ''
                end
                content = result
                index = -1
                next
            end

            if content[index] == open || ((index == 0 || content[index - 1].strip == '' || content[index - 1] == close) && (content[index] == '@' || content[index] == ':'))
              if text.length > 0
                node.append_text(text)
                text = ''
              end
              
              if content[index] == '@'
                content = self.parse_at_tag(node, content[(index + 1)..content.length])
              elsif content[index] == ':'
                if result = self.parse_emoticon_alias(node, content[index..content.length])
                  content = result
                else
                  text << content[index]
                  next
                end
              elsif content[index] == open
                content = self.parse(node.append_node, content[index..content.length], open, close)
              end
              index = -1
              next
            end
            text << content[index]
          end
          
          if state == 0
            if !quote.nil?
              if content[index] == quote
                quote = nil
                next
              end
              
              name << content[index]
              next
            end
            
            if content[index] == '"' || content[index] == "'"
              quote = content[index]
              next
            end
            
            if name.length > 0 && content[index] == '='
              content = self.parse_equals_par(node, content[(index + 1)..content.length], close)
              index = -1
            elsif name.length > 0 && (content[index] == close || content[index] == '/' || content[index] == ' ')
              node.tag_name = name
              
              if content[index] == ' '
                content = self.parse_attributes(node, content[(index + 1)..content.length], close)
                index = -1
              end
              
              state = 1
            else
              name << content[index]
            end
          end
          
          if state == -1 && content[index] == open
            state = 0
          end
        end
        
        node.append_text(text)
        return content[(index + 1)..content.length]
      end
      
      def parse_equals_par(node, content, close)
        index = -1
        quote = nil
        par = ''
        
        while index < content.length - 1
          index = index + 1
          
          if quote.nil?
            if content[index] == '"' || content[index] == "'"
              quote = content[index]
              next
            end
            
            if content[index] == ' ' || content[index] == close
              if par.length > 0
                node.equals_par = par
              end
              
              return content[index..content.length]
            end
          elsif content[index] == quote
            quote = nil
            next
          end
          
          par << content[index]
        end
        
        if par.length > 0
          node.equals_par = par
        end
        
        return content[index..content.length]
      end
      
      def parse_at_tag(node, content)
        at_tag = content.split(/[\s\[\<]/)[0]
        node.append_node('at').append_text(at_tag)
        return content.gsub(at_tag, '')
      end
      
      def parse_reply_tag(node, content)
        reply_tag = content.split(/[^a-z0-9A-Z]/)[0]
        node.append_node('reply').append_text(reply_tag)
        return content.gsub(reply_tag, '')
      end
      
      def parse_url(node, index, content, open, close)
        protocol = content[index..[content.length, (index+5)].min]

        if protocol == 'http:/' || protocol == 'https:'
          url = content[index..content.length].split(open)[0].split(close)[0].split(' ')[0]
          node.append_node('a').set_attribute('href', url)
          return content.sub(url, '')
        end
        
        return false
      end

      def parse_emoticon_alias(node, content)
        emote = content.split(':')
        if emote.length > 1
          emote = emote[1]
          if Emoticons.is_defined_emote(emote)
            node.append_node('emote').append_text(emote)
            return content.sub(':' + emote + ':', '')
          end
        end
        
        return false
      end
      
      def parse_attributes(node, content, close)
        index = -1
        quote = nil
        name = ''
        value = ''
        in_value = false
        
        while index < content.length - 1
          index += 1
          
          if !in_value || quote.nil?
            if content[index] == '/' && index < content.length - 1 && content[index + 1] == close
              return content[index..content.length]
            end
            
            if content[index] == close
              if name.length > 0
                node.set_attribute(name, value)
              end
              return content[(index + 1)..content.length]
            end
          end
          
          if !in_value
            if content[index] == '='
              in_value = true
              next
            end
            
            name << content[index]
          else
            if quote.nil?
              if content[index] == '"' || content[index] == "'"
                quote = content[index]
                next
              end
              
              if content[index] == ' '
                node.set_attribute(name, value)
                name = ''
                value = ''
                in_value = false
                next
              end
            elsif content[index] == quote
              quote = nil
              node.set_attribute(name, value)
              name = ''
              value = ''
              in_value = false
              next
            end
            
            value << content[index]
          end
        end
        
        return content[(index + 1)..content.length]
      end
    end
  end
end
