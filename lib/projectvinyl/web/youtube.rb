require 'projectvinyl/web/ajax'
require 'projectvinyl/bbc/bbcode'
require 'uri'

module ProjectVinyl
  module Web
    class Youtube
      def self.get(url, wanted_data = {})
        meta = Youtubedl.video_meta(url)

        all = flag_set(wanted_data, :all)

        data = {
          id: meta[:id],
          attributes: {
            upload_date: meta[:upload_date],
            extension: meta[:ext],
            codec: meta[:acodec],
            live_stream: {
              is_live: meta[:is_live] || false ,
              start: meta[:start_time],
              end: meta[:end_timer]
            }
          },
          links: {
            embed_url: "https://www.youtube.com/embed/#{meta[:id]}"
          },
          meta: {
            url: url
          },
          included: {}
        }

        data[:attributes][:title] = meta[:fulltitle] || meta[:title] || [] if all || flag_set(wanted_data, :title)
        data[:attributes][:views] = meta[:view_count] if all || flag_set(wanted_data, :views)
        data[:attributes][:duration] = meta[:duration] if all || flag_set(wanted_data, :duration)
        data[:attributes][:coppa] = __coppa(meta) if all || flag_set(wanted_data, :coppa)
        data[:attributes][:description] = __description(meta) if all || flag_set(wanted_data, :description)
        data[:attributes][:rating] = __rating(meta) if all || flag_set(wanted_data, :rating)

        data[:included][:series] = __series(meta) if (all || flag_set(wanted_data, :series)) && (meta[:series_name] || meta[:season_number] || meta[:episode_numer])
        data[:included][:uploader], data[:included][:channel] = __artist(meta, data[:links]) if all || flag_set(wanted_data, :artist)
        data[:included][:thumbnails] = __thumbnails(meta) if all || Youtube.flag_set(wanted_data, :thumbnails)
        data[:included][:tags] = meta[:tags] || [] if all || flag_set(wanted_data, :tags)
        data[:included][:categories] = meta[:categories] || [] if all || flag_set(wanted_data, :categories)
        data[:included][:annotations] = meta[:annotations] || [] if all || flag_set(wanted_data, :annotations)
        data[:included][:captions] = meta[:automatic_captions] || [] if all || flag_set(wanted_data, :captions)
        data[:included][:chapters] = meta[:chapters] || [] if all || flag_set(wanted_data, :chapters)
        data[:included][:sources] = meta[:requested_formats] || [] if all || flag_set(wanted_data, :source)

        data
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
      
      private
      def self.__coppa(meta)
        {
          age_limit: meta[:age_limit].to_i,
          coppa: meta[:age_limit].to_i > 0
        }
      end
      
      def self.__series(meta)
        {
          name: meta[:series],
          season_number: meta[:season_number],
          episode_number: meta[:episode_number]
        }
      end

      def self.__description(meta)
        desc_node = ProjectVinyl::Bbc::Bbcode.from_html(meta[:description] || "")
        {
          html: desc_node.outer_html,
          bbc: desc_node.outer_bbc
        }
      end

      def self.__artist(meta, links)
        links[:uploader_url] = meta[:uploader_url]
        links[:channel_url] = meta[:channel_url]

        [
          {
            id: meta[:uploader_id],
            name: meta[:uploader],
            url: meta[:uploader_url]
          },
          {
            id: meta[:channel_id],
            name: meta[:channel_name],
            url: meta[:channel_url]
          }
        ]
      end

      def self.__rating(meta)
        {
          average: meta[:average_rating],
          likes: meta[:like_count],
          dislikes: meta[:dislike_count]
        }
      end

      def self.__thumbnails(meta)
        thumbnails = meta[:thumbnails].map do |thumbnail|
          {
            url: thumbnail[:url].split("?")[0],
            width: thumbnail[:width],
            height: thumbnail[:height]
          }
        end
        thumbnails << {
          url: "https://i.ytimg.com/vi/#{meta[:id]}/maxresdefault.jpg",
          width: meta[:width],
          height: meta[:height]
        }
        thumbnails
      end

      def self.__shorten_direct_link(url)
        params = Ajax.new(url).params

        required_params = URI.unescape(params['sparams'] || '').split(',')
        required_params += ['sparams', 'sig']
        params = params.select {|k,_| required_params.include? k }

        args = params.entries.map {|entry| "#{entry[0]}=#{entry[1]}"}

        "#{url.split('?')[0]}?#{args.join('&')}"
      end
    end
  end
end
