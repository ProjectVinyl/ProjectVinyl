require 'projectvinyl/bbc/parser/helpers'

module ProjectVinyl
  module Bbc
    module Parser
      module NodeAttributeParser
        JS_ATTR_REG = /^on[a-z]+$/i.freeze

        # Handles ... attr="1" attr="2">
        #         ---|
        # Returns on .../> or ...>
        #            ---|     ---|
        def self.parse(node, content, close)
          index = -1
          name = ''

          while index < (content.length - 1)
            index += 1

            break if Helpers.head_matches?(content, index, "/#{close}")
            break if content[index] == close

            if Helpers.at_any?(content, index, ['=', ' '])
              next if name.blank?
              ( content, value ),index = read_quoted_value(Helpers.rest(content, index + 1), close), -1
              node.set_attribute(name, value) if attribute_name_valid? name
              name = ''
              next
            end

            name << content[index]
          end

          node.set_attribute(name, '') if attribute_name_valid? name
          return Helpers.rest(content, index)
        end

        # Handles <name="equals_par"
        #         ------|
        # Returns on ... attr="1">  or ...>
        #            ---|              ---|
        def self.parse_equals_par(node, content, close)
          content, par = read_quoted_value(content, close)
          node.equals_par = par if par.length > 0
          return content
        end

        def self.read_quoted_value(content, close)
          index = -1
          quote = nil
          value = ''

          while index < (content.length - 1)
            index += 1

            if quote.nil?
              break if Helpers.head_matches?(content, index, "/#{close}")

              if Helpers.is_quote?(content, index)
                quote = content[index]
                next
              end

              break if Helpers.at_any?(content, index, [' ', close])
            elsif content[index] == quote
              index += 1
              break
            end

            value << content[index]
          end

          [Helpers.rest(content, index), value]
        end

        def self.attribute_name_valid?(name)
          !name.blank? && !JS_ATTR_REG.match?(name.strip)
        end
      end
    end
  end
end
