require 'projectvinyl/bbc/embed_generator'

module ProjectVinyl
  module Bbc
    class TagGenerator
      GENERATORS = {
        bbc: [], html: []
      }

      def self.generate(tag, type)
        tag_sym = tag.tag_name.to_sym
        if tag.tag_name.length > 0
          GENERATORS[type].each do |g|
            return g[:func].call(tag) if g[:match].index(tag_sym)
          end
        end

        return self.generate_default_bbc(tag) if type == :bbc
        return self.generate_default_html(tag) if type == :html
        return ''
      end

      def self.generate_default_bbc(tag)
        tag.inner_bbc
      end

      def self.generate_default_html(tag)
        if tag.tag_name.length > 0 && !tag.tag_name.match(/[^0-9]/)
          return EmbedGenerator.to_iframe("/embed/#{tag.tag_name}") + tag.inner_html
        end
        tag.inner_html
      end

      def self.register(type, matcher, &block)
        GENERATORS[type] << {
          match: matcher,
          func: block
        }
      end
    end
  end
end