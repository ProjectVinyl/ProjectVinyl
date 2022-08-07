module ProjectVinyl
  module Bbc
    module Parser
      module Helpers
        def self.at_line_break?(content, index)
          content[index] == '\r' || content[index] == '\n'
        end

        def self.is_quote?(content, index)
          content[index] == '"' || content[index] == "'"
        end

        def self.head_matches?(content, index, expect)
          content.index(expect, index) == index
        end

        def self.head_matches_any?(content, index, expecteds)
          expecteds.any? { |i| head_matches?(content, index, i) }
        end

        def self.at_any?(content, index, expecteds)
          expecteds.any? { |i| content[index] == i }
        end

        def self.rest(content, index)
          content[index..content.length] || ''
        end
      end
    end
  end
end
