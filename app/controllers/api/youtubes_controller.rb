require 'projectvinyl/web/youtube'

module Api
  class YoutubesController < BaseApiController
    def show
      @url = params[:url]

      return fail :unauthorised, status: 302, message: "Invalid Request" if !ProjectVinyl::Web::Youtube.is_video_link(@url)

      succeed ProjectVinyl::Web::Youtube.get(@url, include_hash(ProjectVinyl::Web::Youtube.all_flags))
    end
  end
end
