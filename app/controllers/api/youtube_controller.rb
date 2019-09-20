require 'projectvinyl/web/youtube'

module Api
  class YoutubeController < BaseApiController
    def tube
      ProjectVinyl::Web::Youtube
    end

    def show
      @url = params[:url]

      if !tube.is_video_link(@url)
        return fail :unauthorised, status: 302, message: "Invalid Request"
      end

      succeed id: tube.video_id(@url),
        attributes: tube.get(@url, include_hash([:title, :description, :artist, :thumbnail, :iframe, :source])),
        meta: {
          url: @url
      }
    end
  end
end
