module Admin
  class VideosController < BaseAdminController
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

    def hidden
      page(Video.where(hidden: true), true)
    end

    def unprocessed
      page(Video.where("(processed IS NULL or processed = false) AND hidden = false"), true)
    end

    def destroy
      badly_named_function do
        if !(video = Video.where(id: params[:id]).first)
          return flash[:error] = "Video not be found"
        end

        video.destroy
        flash[:notice] = "1 Item(s) deleted successfully"
      end
    end

    def moderation
      try_to do |video|
        video.moderation_note = params[:video][:moderation_note]
        video.save
      end
    end
    
    def batch_drop
      badly_named_function do
        len = Video.where(hidden: true).count
        Video.where(hidden: true).destroy
        flash[:notice] = "#{len} item(s) deleted successfully."
      end
    end
    
    def requeue
      badly_named_function do
        flash[:notice] = "#{Verification::Video.rebuild_queue} videos in queue."
      end
    end

    def metadata
      try_to do |video|
        result = video.pull_meta(params[:source], params)

        if result == :ok
          flash[:notice] = "The video was updated succesfully."
        elsif result == :not_found
          flash[:error] = "Video source was not found."
        else
          flash[:error] = "Error #{result}."
        end
      end
    end
    
    def reprocess
      try_to do |video|
        flash[:notice] = "Processing Video: #{video.generate_webm}"
      end
    end
    
    def resetthumb
      try_to do |video|
        video.set_thumbnail
        flash[:notice] = "Thumbnail Reset."
      end
    end
    
    def merge
      try_to do |video|
        flash[:notice] = "Changes Saved."
        
        if other = Video.where(id: params[:video][:duplicate_id]).first
          return video.merge(current_user, other)
        end
        
        video.unmerge
      end
    end
    
    def feature
      check_then do |video|
        Video.where(featured: true).update_all(featured: false)
        render json: {
          added: video.featured = !video.featured
        }
        
        if video.featured
          video.save
          Tag.add_tag('featured video', video)
        end
      end
    end
    
    def hide
      check_then do |video|
        video.set_hidden(!video.hidden)
        video.save
        
        render json: {
          added: video.hidden
        }
      end
    end
    
    private
    def page(records, reverse)
      render_pagination 'admin/videos/thumb_h', records.with_likes(current_user), params[:page].to_i, 40, reverse
    end
    
    def check_then
      if !current_user.is_staff?
        return head :unauthorized
      end
      
      if !(video = Video.where(id: params[:video_id]).first)
        return head :not_found
      end
      
      yield(video)
    end
    
    def badly_named_function
      redirect_to action: :view, controller: 'admin/admin'
      
      if !current_user.is_contributor?
        return flash[:error] = "Access Denied: You can't do that right now."
      end
      
      yield
    end
    
    def try_to
      redirect_to action: 'show', id: params[:video_id]
      
      if !current_user.is_contributor?
        return flash[:error] = "Error: Login required."
      end
      
      if !(video = Video.where(id: params[:video_id]).first)
        return flash[:error] = "Error: Video not found."
      end
      
      yield(video)
    end
  end
end
