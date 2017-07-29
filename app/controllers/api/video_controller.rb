module Api
  class VideoController < ApplicationController
    def find
      @videos = Video.where('title LIKE ?', '%' + params[:q] + '%').limit(10)
      @videos = @videos.map(&:json)
      render json: @videos
    end

    def details
      if @video = Video.where(id: params[:id]).first && (!@video.hidden || (user_signed_in? && current_user.is_contributor?))
        return render json: @video.json
      end
      head 404
    end
    
    def update
      id = params[:id] || (params[:video] ? params[:video][:id] : nil)
      if user_signed_in? && @video = Video.where(id: id).first
        if @video.user_id == current_user.id || current_user.is_contributor?
          if params[:tags]
            if changes = Tag.load_tags(params[:tags], @video)
              TagHistory.record_changes(current_user, @video, changes[0], changes[1])
            end
          end
          if params[:source] && (@video.source != params[:source])
            @video.set_source(params[:source])
            TagHistory.record_source_change(current_user, @video, @video.source)
          end
          @video.set_description(params[:description]) if params[:description]
          @video.set_title(params[:title]) if params[:title]
          @video.save
          return render json: {
            results: Tag.tag_json(@video.tags),
            source: @video.source
          }
        end
      end
      head 401
    end
  end
end
