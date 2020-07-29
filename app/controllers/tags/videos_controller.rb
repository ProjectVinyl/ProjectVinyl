module Tags
  class VideosController < ApplicationController
    def index
      return head :not_found if !(@tag = Tag.where(id: params[:tag_id]).first)
      @records = @tag.videos.where(hidden: false).includes(:tags).order(:created_at)
      render_pagination 'videos/thumb_h', @records, params[:page].to_i, 8, true
    end
  end
end
