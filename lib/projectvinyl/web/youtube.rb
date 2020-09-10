require 'projectvinyl/web/ajax'
require 'projectvinyl/bbc/bbcode'
require 'projectvinyl/bbc/parser/node_finder'
require 'uri'
require 'net/http'

module ProjectVinyl
  module Web
    class Youtube
      def self.get(url, wanted_data = {})
        output_data = {}

        @all = Youtube.flag_set(wanted_data, :all)

        if @all ||
            Youtube.flag_set(wanted_data, :title) ||
            Youtube.flag_set(wanted_data, :artist) ||
            Youtube.flag_set(wanted_data, :thumbnail) ||
            Youtube.flag_set(wanted_data, :iframe)
          Ajax.get('https://www.youtube.com/oembed', url: 'http:' + url.sub(/http?(s):/, ''), format: 'json') do |body|
            begin
              body = JSON.parse(body)

              if @all || Youtube.flag_set(wanted_data, :title)
                output_data[:title] = body['title']
              end

              if @all || Youtube.flag_set(wanted_data, :artist)
                output_data[:artist] = {
                  id: body['author_url'].split('/').last,
                  name: body['author_name'],
                  url: body['author_url']
                }
              end

              if @all || Youtube.flag_set(wanted_data, :thumbnail)
                output_data[:thumbnail] = {
                  url: body['thumbnail_url'],
                  maxres: body['thumbnail_url'].sub("/hqdefault.jpg", "/maxresdefault.jpg"),
                  width: body['thumbnail_width'],
                  height: body['thumbnail_height']
                }
              end

              if @all || Youtube.flag_set(wanted_data, :iframe)
                output_data[:iframe] = body['html']
              end
            rescue e
            end
          end
        end

        if @all ||
            Youtube.flag_set(wanted_data, :description) ||
            Youtube.flag_set(wanted_data, :source) ||
            Youtube.flag_set(wanted_data, :coppa) ||
            Youtube.flag_set(wanted_data, :tags)
          Ajax.get(url) do |body|
            body = body.force_encoding('utf-8')

            if @all || Youtube.flag_set(wanted_data, :coppa)
              output_data[:coppa] = !!body.index('isFamilySafe\\":true')
            end

            if @all || Youtube.flag_set(wanted_data, :description)
              if desk = Youtube.description_from_html(body)
                desc_node = ProjectVinyl::Bbc::Bbcode.from_html(desk)

                desc_node.getElementsByTagName('a').each do |a|
                  if a.attributes[:href].index('redirect?')
                    a.attributes[:href] = extract_uri_parameter(a.attributes[:href], 'q')
                  end
                  if a.attributes[:href].index('/') == 0
                    a.attributes[:href] = 'https://www.youtube.com' + a.attributes[:href]
                  end
                  a.inner_text = a.attributes[:href]
                end

                output_data[:description] = {
                  html: desc_node.outer_html,
                  bbc: desc_node.outer_bbc
                }
              end
            end

            if @all || Youtube.flag_set(wanted_data, :tags)
              if (tgs = Youtube.header_from_html(body))
                output_data[:tags] = ProjectVinyl::Bbc::Parser::NodeFinder.parse(tgs, '<', '>', 'meta')
                    .filter{ |meta| meta.attributes[:property] == "og:video:tag" }
                    .map{ |meta| meta.attributes[:content] }
              end
            end

            if @all || Youtube.flag_set(wanted_data, :source)
              if src = Youtube.source_from_html(body)
                output_data[:source] = src
              end
            end
          end
        end

        output_data
      end

      def self.source_from_html(html)
        map_index = html.index('url_encoded_fmt_stream_map')
        return Youtube.source_from_html_two(html) if !map_index

        html = html[map_index..html.length]
        html = html.split('<')[0]
        html = html.split('"')[2]
        html = html.split(',')
        html = html.map {|s| URI.unescape(s)}
        html = html.map {|s| s.split('\\u0026')}

        html.map do |el|
          o = {}

          el.each do |s|
            key = s.split('=')[0]
            o[key.to_sym] = s.gsub(key + '=', '')
          end

          o
        end
      end

      def self.source_from_html_two(html)
        player_response(html)['streamingData']
      end

      def self.player_response(html)
        map_index = html.index('ytplayer.config = ')
        return nil if !map_index

        html = html[(map_index + 'ytplayer.config = '.length)..html.length]
        html = html.split(';ytplayer.')[0]
        while html[html.length - 1] == ';'
          html = html[0..(html.length - 2)]
        end
        html = JSON.parse(html)['args']

        JSON.parse(html['player_response'])
      end

      def self.description_from_html(html)
        close = '</p>'
        description_index = html.index('id="eow-description"')
        if !description_index
          close = '</div>'
          description_index = html.index('id="description"')
        end

        if !description_index
          player_resp = player_response(html)

          if player_resp
            player_resp = player_resp["videoDetails"]
            if player_resp
              player_resp = player_resp["shortDescription"]
              return player_resp if player_resp
            end
          end

          return nil
        end

        html = html[description_index..html.length]
        html = html.split(close)[0].split('>')
        html.shift
        html.join('>')
      end

      def self.shorten_direct_link(url)
        params = Ajax.new(url).params

        required_params = URI.unescape(params['sparams'] || '').split(',')
        required_params += ['sparams', 'sig']
        params = params.select {|k,_| required_params.include? k }

        args = params.entries.map {|entry| "#{entry[0]}=#{entry[1]}"}

        "#{url.split('?')[0]}?#{args.join('&')}"
      end

      def self.header_from_html(html)
        html.split('</head>')[0]
      end

      def self.is_video_link(url)
        if url.nil? || (url = url.strip).empty?
          return false
        end
        !(url =~ /http?(s):\/\/(www\.|m\.)(youtube\.[^\/]+\/(watch\?.*v=|embed\/)|youtu\.be\/)([^&]+)/).nil?
      end

      def self.embed_url(url)
        "https://www.youtube.com/embed/#{video_id(url)}"
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
