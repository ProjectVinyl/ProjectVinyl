require 'projectvinyl/bbc/parser/node_attribute_parser'
require 'projectvinyl/bbc/node'

module ProjectVinyl
  module Bbc
    module Parser
      class NodeFinder

        def self.parse(content, open, close, tag_name)
          nodes = []

          while (content.length > 0)
            index = content.index(open + tag_name)

            return nodes if index.nil? || index < 0

            content = content[(index + tag_name.length + 1)..content.length].strip
            node = Node.new(nil, tag_name)
            nodes << node
            content = NodeAttributeParser.parse(node, content, close)
          end

          return nodes
        end
      end
    end
  end
end
