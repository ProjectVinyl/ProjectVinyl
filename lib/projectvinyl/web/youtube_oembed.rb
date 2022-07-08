require 'projectvinyl/web/ajax'
require 'projectvinyl/web/youtube'
require 'uri'

module ProjectVinyl
  module Web
    class YoutubeOembed
      API_URL = 'https://www.youtube.com/oembed'.freeze

      def self.get(id)
        output = {}
        puts API_URL + Youtube.video_url(id).to_query('url')
        Ajax.get(API_URL, {
          url: Youtube.video_url(id),
          format: :json
        }) do |response|
          output = JSON.parse(response, symbolize_names: true)
        end
        return output
      end
    end
  end
end
