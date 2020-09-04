require 'projectvinyl/bbc/parser/node_attribute_parser'
require 'projectvinyl/bbc/parser/node_content_parser'
require 'projectvinyl/bbc/node'

module ProjectVinyl
  module Bbc
    module Parser
      class NodeDocumentParser
        INITIAL_STATE = -1
        TAG_NODE = 0
        TAG_CONTENT = 1
        
        def self.parse(text, open, close)
          result = Node.new(nil, 'Document')
          parse_document(result, open + result.tag_name + close + text + open + '/' + result.tag_name + close, open, close)
          return result
        end

        def self.parse_document(node, content, open, close)
          index = -1
          state = INITIAL_STATE
          name = ''
          text = ''
          quote = nil

          while (index < content.length - 1)
            index += 1

            if state == TAG_CONTENT
              # Self-terminating tags
              if node.self_closed?
                index += 1 if content[index] == '/' || content[index] == close

                return content[index..content.length]
              end

              # Tags without content
              return content[3..content.length] if content.index("/#{close}") == 0

              tag = "#{open}/#{node.tag_name}#{close}"

              # End of tag
              if content.index(tag) == index
                node.append_text(text)
                return content[(index + tag.length)..content.length]
              end

              result = false
              text,result = NodeContentParser.parse(node, content, text, index, open, close)

              if result != false
                content = result
                index = -1
                next
              end

              # Just append and move to the next one
              text << content[index]
            end

            if state == TAG_NODE
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
                content = NodeAttributeParser.parse_equals_par(node, content[(index + 1)..content.length], close)
                index = -1
              elsif name.length > 0 && (content[index] == close || content[index] == '/' || content[index] == ' ')
                node.tag_name = name

                if content[index] == ' '
                  content = NodeAttributeParser.parse(node, content[(index + 1)..content.length], close)
                  index = -1
                end

                state = TAG_CONTENT
              else
                name << content[index]
              end
            end

            state = TAG_NODE if state == INITIAL_STATE && content[index] == open
          end

          node.append_text(text)
          return content[(index + 1)..content.length]
        end
      end
    end
  end
end
