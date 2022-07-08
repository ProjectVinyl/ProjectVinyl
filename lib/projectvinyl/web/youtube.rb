require 'projectvinyl/web/ajax'
require 'projectvinyl/web/the_pony_archive'
require 'projectvinyl/bbc/bbcode'
require 'uri'

module ProjectVinyl
  module Web
    class Youtube
      URL_REG = /((https?:)?\/\/)?(www\.|m\.)?(youtube\.[^\/]+\/(watch\?.*v=|embed\/|shorts\/)|youtu\.be\/)([^&]+)/.freeze
      URL_REG_2 = /((https?:)?\/\/)?i.ytimg.com\/..\/([^\/]+).*/.freeze
      ALL_FLAGS = [
        :title, :views, :duration, :coppa, :description, :rating,
        :series, :artist, :thumbnails, :tags, :categories, :annotations,
        :captions, :chapters, :sources
      ].freeze

      def self.all_flags
        ALL_FLAGS
      end

      def self.get(url, wanted_data = {})
        id = video_id(url)
        return {error: "Not a video: #{url}" } if id.nil?
        meta = Youtubedl.video_meta(url)
        if meta.key?(:error)
          puts "Youtube Error: #{meta[:error]}"
          meta = ThePonyArchive.video_meta(id) if !id.nil?
          meta = meta[:metadata] if meta.key?(:metadata)
        end

        return meta if meta.nil? || meta.key?(:error)
        parse_metadata(meta, wanted_data)
      end

      def self.parse_metadata(meta, wanted_data = {})
        all = flag_set(wanted_data, :all)

        data = {
          id: meta[:id],
          attributes: {
            visibility: meta[:availability],
            upload_date: meta[:upload_date],
            release_date: meta[:release_timestamp],
            extension: meta[:ext],
            codec: {
              audio: meta[:acodec],
              video: meta[:vcodec]
            },
            live_stream: {
              is_live: meta[:is_live] || meta[:live_status] == 'live' || false,
              was_live: meta[:was_live] || false,
              start: meta[:start_time],
              end: meta[:end_timer]
            },
            dimensions: {
              width: meta[:width],
              height: meta[:height]
            }
          },
          links: {
            embed_url: unchecked_embed_url(meta[:id])
          },
          meta: {
            url: video_url(meta[:id])
          },
          included: {}
        }

        data[:attributes][:title] = meta[:fulltitle] || meta[:title] || [] if all || flag_set(wanted_data, :title)
        data[:attributes][:views] = meta[:view_count] if all || flag_set(wanted_data, :views)
        data[:attributes][:duration] = meta[:duration] if all || flag_set(wanted_data, :duration)
        data[:attributes][:coppa] = __coppa(meta) if all || flag_set(wanted_data, :coppa)
        data[:attributes][:description] = __description(meta) if all || flag_set(wanted_data, :description)
        data[:attributes][:rating] = ReturnYTDislike.get(meta[:id]) if all || flag_set(wanted_data, :rating)

        data[:included][:series] = __series(meta) if (all || flag_set(wanted_data, :series)) && (meta[:series_name] || meta[:season_number] || meta[:episode_numer])
        data[:included][:uploader], data[:included][:channel] = __artist(meta, data[:links]) if all || flag_set(wanted_data, :artist)
        data[:included][:thumbnails] = __thumbnails(meta) if all || Youtube.flag_set(wanted_data, :thumbnails)
        data[:included][:tags] = meta[:tags] || [] if all || flag_set(wanted_data, :tags)
        data[:included][:categories] = meta[:categories] || [] if all || flag_set(wanted_data, :categories)
        data[:included][:annotations] = meta[:annotations] || [] if all || flag_set(wanted_data, :annotations)
        data[:included][:captions] = meta[:automatic_captions] || [] if all || flag_set(wanted_data, :captions)
        data[:included][:chapters] = meta[:chapters] || [] if all || flag_set(wanted_data, :chapters)
        data[:included][:sources] = meta[:requested_formats] || [] if all || flag_set(wanted_data, :sources)

        data
      end

      def self.download_thumbnail(id)
        Ajax.get(thumbnail_url(id))
      end

      def self.is_video_link(url)
        validate_id(video_id(url)).nil?
      end

      def self.validate_id(id)
        return 'Invalid id: nil' if id.blank?
        return 'Invalid length: Id must be 11 characters' if id.length != 11
        return 'Invalid characters: Id can only contain [a-zA-Z0-9_0]' if /[^a-zA-Z0-9_-]/.match(id)
        # https://webapps.stackexchange.com/questions/54443/format-for-id-of-youtube-video
        return 'Invalid id' if !/[0-9A-Za-z_-]{10}[048AEIMQUYcgkosw]/.match?(id)
        nil
      end

      def self.validate_id!(id)
        error = validate_id id
        raise error if !error.nil?
        id
      end

      def self.embed_url(url)
        "https://www.youtube.com/embed/#{validate_id!(video_id(url))}"
      end

      def self.unchecked_embed_url(id)
        "https://www.youtube.com/embed/#{validate_id!(id)}"
      end

      def self.thumbnail_url(id)
        "https://i.ytimg.com/vi/#{validate_id!(id)}/maxresdefault.jpg"
      end

      def self.video_url(id)
        "https://www.youtube.com/watch?v=#{validate_id!(id)}"
      end

      def self.video_id(url)
        return nil if url.blank?
        URL_REG.match(url).to_a.last || URL_REG_2.match(url).to_a.last
      end

      def self.flag_set(hash, key)
        hash.key?(key) && hash[key]
      end

      private
      def self.__coppa(meta)
        {
          age_limit: meta[:age_limit].to_i,
          coppa: meta[:__coppa].present?
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

      def self.__thumbnails(meta)
        thumbnails = meta[:thumbnails].map do |thumbnail|
          {
            url: thumbnail[:url].split("?")[0],
            width: thumbnail[:width] || 0,
            height: thumbnail[:height] || 0
          }
        end
        thumbnails << {
          url: thumbnail_url(meta[:id]),
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

    class ReturnYTDislike
      API_URL = 'https://returnyoutubedislikeapi.com/votes'.freeze

      def self.get(videoId)
        output = Ajax.get(API_URL, videoid: videoId)
        return {} if output.nil?
        JSON.parse(output, symbolize_names: true).slice(:likes, :dislikes, :rating, :viewCount)
      end
    end
  end
end
