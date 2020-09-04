module ProjectVinyl
  module Bbc
    module Parser
      class NodeAttributeParser

        def self.parse_equals_par(node, content, close)
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
                node.equals_par = par if par.length > 0

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

        def self.parse(node, content, close)
          index = -1
          quote = nil
          name = ''
          value = ''
          in_value = false

          while index < content.length - 1
            index += 1

            if !in_value || quote.nil?
              return content[index..content.length] if content[index] == '/' && index < content.length - 1 && content[index + 1] == close

              if content[index] == close
                node.set_attribute(name, value) if name.length > 0

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
end
