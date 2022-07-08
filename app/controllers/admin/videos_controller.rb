module Admin
  class VideosController < Admin::Videos::BaseVideosAdminController
    def show
      return render_access_denied if !current_user.is_contributor?

      if !(@video = Video.where(id: params[:id]).with_likes(current_user).first)
        return render_error(
          title: 'Nothing to see here!',
          description: 'This is not the video you are looking for.'
        )
      end

      if !@video.comment_thread
        @video.create_comment_thread(title: @video.title)
        @video.comment_thread.save
      end

      @modifications_allowed = true
      @user = @video.user
      @tags = @video.tags
      @comments = @video.comment_thread.comments
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
        return flash[:error] = "Video not be found" if !(video = Video.where(id: params[:id]).first)
        video.destroy
        flash[:notice] = "1 Item(s) deleted successfully"
      end
    end
  end
end
