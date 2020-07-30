require 'projectvinyl/search/parser/query_parser'
require 'projectvinyl/search/parser/lexer_error'
require 'projectvinyl/search/parser/input_error'
require 'projectvinyl/search/exceptable'

module ProjectVinyl
  module Search
    module Parser
      class ParsedQuery
        include ProjectVinyl::Search::Exceptable

        def initialize(search_terms, index_params, sender)
          @root = QueryParser.new
          @root.take_all(Parser::Opset.new(search_terms, index_params), sender)
        rescue InputError => e
          excepted! e, 1
        rescue LexerError => e
          excepted! e, 2
        rescue => e
          excepted! e
          puts "Exception raised #{e}"
          puts "Backtrace:\n\t#{e.backtrace[0..8].join("\n\t")}"
        end

        def tags
          @root.tags
        end

        def uses(sym)
          @root.uses sym
        end

        def to_hash
          @root.to_hash
        end
      end
    end
  end
end
