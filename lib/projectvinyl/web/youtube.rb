require 'projectvinyl/web/ajax'
require 'projectvinyl/bbc/bbcode'

module ProjectVinyl
  module Web
    class Youtube
      def self.get(url, wanted_data = {})
        if Youtube.flag_set(wanted_data, :all) ||
            Youtube.flag_set(wanted_data, :title) ||
            Youtube.flag_set(wanted_data, :artist) ||
            Youtube.flag_set(wanted_data, :thumbnail) ||
            Youtube.flag_set(wanted_data, :iframe)
          Ajax.get('https://www.youtube.com/oembed', url: 'http:' + url.sub(/http?(s):/, ''), format: 'json') do |body|
            begin
              body = JSON.parse(body)
              if Youtube.flag_set(wanted_data, :all)
                wanted_data[:all] = body
              end
              if Youtube.flag_set(wanted_data, :title)
                wanted_data[:title] = body['title']
              end
              if Youtube.flag_set(wanted_data, :artist)
                wanted_data[:artist] = {
                  name: body['author_name'],
                  url: body['author_url']
                }
              end
              if Youtube.flag_set(wanted_data, :thumbnail)
                wanted_data[:thumbnail] = {
                  url: body['thumbnail_url'],
                  width: body['thumbnail_width'],
                  height: body['thumbnail_height']
                }
              end
              if Youtube.flag_set(wanted_data, :iframe)
                wanted_data[:iframe] = body['html']
              end
            rescue e
            end
          end
        end
        if Youtube.flag_set(wanted_data, :description)
          Ajax.get(url) do |body|
            if desk = Youtube.description_from_html(body)
              desc_node = ProjectVinyl::Bbc::Bbcode.from_html(desk)
              desc_node.getElementsByTagName('a').each do |a|
                if a.attributes[:href].index('redirect?')
                  a.attributes[:href] = extract_uri_parameter(a.attributes[:href], 'q')
                end
                a.inner_text = a.attributes[:href]
              end
              wanted_data[:description] = {
                html: desc_node.outer_html,
                bbc: desc_node.outer_bbc
              }
            end
          end
        end
        wanted_data
      end
      
      def self.description_from_html(html)
        description_index = html.index('id="eow-description"')
        return nil if !description_index
        html = html[description_index..html.length]
        html = html.split('</p>')[0].split('>')
        html.shift
        html.join('>')
      end
      
      def self.is_video_link(url)
        if url.nil? || (url = url.strip).empty?
          return false
        end
        !(url =~ /http?(s):\/\/(www\.|m\.)(youtube\.[^\/]+\/watch\?.*v=|youtu\.be\/)([^&]+)/).nil?
      end
      
      def self.video_id(url)
        return url.split('v=')[1].split('&')[0] if url.index('v=')
        url.split('?')[0].split('/').last
      end
      
      def self.flag_set(hash, key)
        hash.key?(key) && hash[key]
      end
      
      def self.extract_uri_parameter(url, parameter)
        Rack::Utils.parse_nested_query(URI.parse(url).query)[parameter]
      end
    end
  end
end
