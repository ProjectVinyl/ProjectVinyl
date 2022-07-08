require 'projectvinyl/web/ajax'
require 'projectvinyl/web/youtube'
require 'uri'

module ProjectVinyl
  module Web
    class YoutubeOembed
      API_URL = 'https://www.youtube.com/oembed'.freeze

      def self.get(id)
        output = Ajax.get(API_URL, url: Youtube.video_url(id), format: :json)
        return {} if output.nil?
        JSON.parse(output, symbolize_names: true)
      end
    end
  end
end
