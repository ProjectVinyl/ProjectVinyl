module Admin
  class VideosController < Admin::Videos::BaseVideosAdminController
    def show
      if !current_user.is_contributor?
        return render_access_denied
      end
      
      if !(@video = Video.where(id: params[:id]).with_likes(current_user).first)
        return render_error(
          title: 'Nothing to see here!',
          description: 'This is not the video you are looking for.'
        )
      end
      
      @modifications_allowed = true
      @user = @video.user
      @tags = @video.tags
      @crumb = {
        stack: [
          { link: '/admin', title: 'Admin' },
          { title: 'Videos' },
          { link: @video.link, title: @video.id }
        ],
        title: @video.title
      }
    end

    def destroy
      check_access_then do
        if !(video = Video.where(id: params[:id]).first)
          return flash[:error] = "Video not be found"
        end

        video.destroy
        flash[:notice] = "1 Item(s) deleted successfully"
      end
    end
  end
end
