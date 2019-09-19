module Videos
  class CoversController < BaseVideosController
    def update
      if !user_signed_in?
        error(params[:format] == 'json', "Access Denied", "You can't do that right now.")
      end

      if !(video = Video.where(id: params[:video_id]).first)
        error(params[:format] == 'json', "Nothing to see here!", "This is not the video you are looking for.")
      end

      if !video.owned_by(current_user)
        error(params[:format] == 'json', "Access Denied", "You can't do that right now.")
      end

      if current_user.is_staff? && (file = params[:video][:file])
        video.set_file(file)
      end

      cover = params[:video][:cover] || !params[:erase]
      video.set_thumbnail(cover, params[:video][:time])

      video.save

      flash[:notice] = "Changes saved successfully. You may need to refresh the page."
      if params[:format] == 'json'
        return render json: {
          result: "success",
          ref: video.ref
        }
      end

      redirect_to action: :show, id: video.id
    end
  end
end
