module Videos
  class CoversController < BaseVideosController
    def update
      error(params[:format] == 'json', "Access Denied", "You can't do that right now.") if !user_signed_in?

      if !(video = Video.where(id: params[:video_id]).first)
        error(params[:format] == 'json', "Nothing to see here!", "This is not the video you are looking for.")
      end

      error(params[:format] == 'json', "Access Denied", "You can't do that right now.") if !video.owned_by(current_user)

      video.set_file(file) if current_user.is_staff? && (file = params[:video][:file])
      cover = params[:video][:cover] || !params[:erase]
      video.set_thumbnail(cover, params[:video][:time])

      video.save

      flash[:notice] = "Changes saved successfully. You may need to refresh the page."
      return redirect_to action: :show, id: video.id if params[:format] != 'json'
      render json: {
        result: "success",
        ref: video.ref
      }      
    end
  end
end
