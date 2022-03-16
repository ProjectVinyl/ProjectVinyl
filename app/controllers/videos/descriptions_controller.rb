module Videos
  class DescriptionsController < BaseVideosController
    def update
      return head 401 if !user_signed_in?
      return head :not_found if !(video = Video.where(id: params[:video_id]).first)
      return head 401 if !video.owned_by(current_user)

      if params[:field] == 'description'
        video.description = params[:value]
        render json: { content: BbcodeHelper.emotify(video.description) }
      elsif params[:field] == 'title'
        video.title = params[:value]
        render json: { content: video.title }
      end

      video.save
    end
  end
end
