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
            if g[:match].index(tag_sym)
              return g[:func].call(tag)
            end
          end
        end
        
        if type == :bbc
          return self.generate_default_bbc(tag)
        end
        
        if type == :html
          return self.generate_default_html(tag)
        end
        
        return ''
      end
      
      def self.generate_default_bbc(tag)
        tag.inner_bbc
      end
      
      def self.generate_default_html(tag)
        if tag.tag_name.index('yt') == 0 && !tag.tag_name.sub('yt', '').match(/[^a-zA-z0-9\-_]/)
          return "<iframe allowfullscreen class=\"embed\" src=\"https://www.youtube.com/embed/#{tag.tag_name.sub('yt', '')}\"></iframe>#{tag.inner_html}";
        end
        if tag.tag_name.length > 0 && !tag.tag_name.match(/[^0-9]/)
          return "<iframe allowfullscreen class=\"embed\" src=\"/embed/#{tag.tag_name}\"></iframe>#{tag.inner_html}"
        end
        return tag.inner_html;
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