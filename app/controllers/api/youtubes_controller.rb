require 'projectvinyl/web/youtube'

module Api
  class YoutubesController < BaseApiController
    def tube
      ProjectVinyl::Web::Youtube
    end

    def show
      @url = params[:url]

      return fail :unauthorised, status: 302, message: "Invalid Request" if !tube.is_video_link(@url)

      succeed id: tube.video_id(@url),
        attributes: tube.get(@url, include_hash([:title, :description, :artist, :thumbnail, :iframe, :source, :coppa, :tags, :views, :rating, :duration])),
        meta: {
          url: @url
      }
    end
  end
end
