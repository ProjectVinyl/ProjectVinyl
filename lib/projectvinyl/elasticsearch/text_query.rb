module ProjectVinyl
  module ElasticSearch
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

      def self.make_term(tag)
        return { wildcard: { tags: tag } } if tag.include?('*')
        {
          term: {
            tags: tag
          }
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
