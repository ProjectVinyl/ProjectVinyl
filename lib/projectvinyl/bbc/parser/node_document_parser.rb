require 'projectvinyl/bbc/parser/node_attribute_parser'
require 'projectvinyl/bbc/parser/node_content_parser'
require 'projectvinyl/bbc/node'
require 'projectvinyl/bbc/parser/helpers'

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
                index += 1 while content[index].blank?
                index += 2 if Helpers.head_matches?(content, index, "/#{close}")

                return Helpers.rest(content, index)
              end

              # Tags without content
              return content[3..content.length] if Helpers.head_matches?(content, index, "/#{close}")

              must_close, close_at = node.closing?(content, index, open, close)
              # End of tag
              if must_close
                node.append_text(text)
                return Helpers.rest(content, index + close_at)
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
          return Helpers.rest(content, index + 1)
        end
      end
    end
  end
end
