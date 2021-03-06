require 'projectvinyl/search/parser/op'

module ProjectVinyl
  module Search
    module Parser
      class TextQuery
        def self.read(opset)
          key = opset.shift_data(Op::TEXT_EQUAL, 'field')
          text = opset.shift_data(Op::TEXT_EQUAL, 'value')

          slugs = text.gsub(' ', '* *').split(' ').map do |slug|
            self.make_slug(key, slug)
          end

          return slugs[0] if slugs.length == 1

          {
            bool: {
              must: slugs
            }
          }
        end

        def self.make_term(field, tag)
          return { wildcard: { field => tag } } if tag.include?('*')
          {
            term: { field => tag }
          }
        end

        def self.make_slug(key, slug)
          {
            wildcard: {
              key.to_sym => {
                value: '*' + slug + '*',
                boost: 1,
                rewrite: :constant_score
              }
            }
          }
        end
      end
    end
  end
end
