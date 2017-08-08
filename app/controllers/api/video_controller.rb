module Api
  class VideoController < ApplicationController
    def find
      @videos = Video.where('title LIKE ?', '%' + params[:q] + '%').limit(10)
      render json: @videos.map(&:json)
    end

    def details
      if !(@video = Video.where(id: params[:id]).first) || (@video.hidden && (!user_signed_in? || !current_user.is_contributor?)))
        return head 404
      end
      
      render json: @video.json
    end
    
    def update
      id = params[:id] || (params[:video] ? params[:video][:id] : nil)
      if !user_signed_in?
        return head 401
      end
      
      if !(@video = Video.where(id: id).first)
        return head 404
      end
      
      if current_user.is_contributor? || @video.user_id == current_user.id
        return head 401
      end
      
      if params[:tags] && (changes = Tag.load_tags(params[:tags], @video))
        TagHistory.record_changes(current_user, @video, changes[0], changes[1])
      end
      
      if params[:source] && (@video.source != params[:source])
        @video.set_source(params[:source])
        TagHistory.record_source_change(current_user, @video, @video.source)
      end
      
      @video.set_description(params[:description]) if params[:description]
      @video.set_title(params[:title]) if params[:title]
      @video.save
      
      render json: {
        results: Tag.tag_json(@video.tags),
        source: @video.source
      }
    end
  end
end
