require 'projectvinyl/bbc/parser/node_attribute_parser'
require 'projectvinyl/bbc/parser/node_content_parser'
require 'projectvinyl/bbc/node'
require 'projectvinyl/bbc/document'
require 'projectvinyl/bbc/parser/helpers'

module ProjectVinyl
  module Bbc
    module Parser
      module NodeDocumentParser
        INITIAL_STATE = -1
        TAG_NODE = 0
        TAG_CONTENT = 1

        def self.parse(text, open, close)
          document = Document.new
          parse_node_inner(document, document, text, open, close)
          document
        end

        def self.parse_node_inner(parent_node, content_node, content, open, close)
          index = -1
          text = ''

          while index < (content.length - 1)
            index += 1

            must_close, close_at = parent_node.closing?(content, index, open, close)
            # End of tag
            if must_close
              index += close_at
              break
            end

            # Illegal combinations - pass them through and render as escaped literals
            if Helpers.head_matches_any?(content, index, ["#{open}#{open}", "#{close}#{close}#{close}", "#{close}#{close}#{open}", "#{open}#{close}"])
              text += content[index]
              next
            end

            if content[index] == open
              # text<name...
              # -- -|
              content_node.append_text(text)
              text = ''
              content, index = parse_node_outer(content_node, Helpers.rest(content, index + 1), open, close), -1
              next
            else
              # Just append and move to the next one
              # text << content[index]
              handled = false
              text,handled = NodeContentParser.parse(content_node, content, text, index, open, close)

              if handled != false
                content,index = handled,-1
                next
              else
                text += content[index]
              end
            end
          end

          content_node.append_text(text)
          return Helpers.rest(content, index)
        end

        def self.parse_node_outer(parent_node, content, open, close)
          name = ''
          index = -1

          while index < (content.length - 1)
            index += 1

            if name.length > 0 && Helpers.at_any?(content, index, ['=', close, ' ', '/'])
              return "&lt;" + content if name.strip != name || name.gsub(/[^a-zA-Z0-9]/, '') != name
              # <name>... or <name ... or <name />
              # -----|       -----|       ------|
              child_node = parent_node.append_node(name)
              # <name=...
              # -----|
              content, index = NodeAttributeParser.parse_equals_par(child_node, Helpers.rest(content, index + 1), close), 0 if content[index] == '='
              # <name attr="1"...
              # -----|
              content, index = NodeAttributeParser.parse(child_node, Helpers.rest(content, index), close), 0 if content[[0, index].max] == ' '
              # <name />... or <name>
              # ------|        -----|

              return Helpers.rest(content, index + close.length + 1) if Helpers.head_matches?(content, index, "/#{close}")

              content_node = (child_node.self_closed? ? parent_node : child_node)
              content, index = parse_node_inner(child_node, content_node, Helpers.rest(content, index + 1), open, close), -1
              return Helpers.rest(content, index + 1)
            else
              name << content[index]
            end
          end

          content
        end
      end
    end
  end
end
