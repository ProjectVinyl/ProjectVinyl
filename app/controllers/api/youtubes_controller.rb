require 'projectvinyl/web/youtube'

module Api
  class YoutubesController < BaseApiController
    ALLOWED = [
      :title, :views, :duration, :coppa, :description, :artist,
      :rating, :thumbnails, :tags, :annotations, :sources
    ].freeze

    def show
      @url = params[:url]

      return fail :unauthorised, status: 302, message: "Invalid Request" if !ProjectVinyl::Web::Youtube.is_video_link(@url)

      succeed ProjectVinyl::Web::Youtube.get(@url, include_hash(ALLOWED))
    end
  end
end
