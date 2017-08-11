module Admin
  class VideoController < ApplicationController
    before_action :authenticate_user!

    def view
      if !current_user.is_contributor?
        return render_access_denied
      end
      
      if !(@video = Video.where(id: params[:id]).first)
        return render_error(
          title: 'Nothing to see here!',
          description: 'This is not the video you are looking for.'
        )
      end
      
      @modifications_allowed = true
      @user = @video.user
      @tags = @video.tags
    end
    
    def hidden
      @records = Video.where(hidden: true)
      render_pagination 'admin/video/thumb_h', @records, params[:page].to_i, 40, true
    end
    
    def unprocessed
      @records = Video.where("(processed IS NULL or processed = ?) AND hidden = false", false)
      render_pagination 'admin/video/thumb_h', @records, params[:page].to_i, 40, false
    end
    
    def destroy
      badly_named_function do
        if !(video = Video.where(id: params[:id]).first)
          return flash[:error] = "Video not be found"
        end
        
        video.remove_self
        flash[:notice] = "1 Item(s) deleted successfully"
      end
    end
    
    def batch_drop
      badly_named_function do
        videos = Video.where(hidden: true)
        videos.each(&:remove_self)
        flash[:notice] = "#{videos.length} Item(s) deleted successfully."
      end
    end
    
    def rebuild_queue
      badly_named_function do
        flash[:notice] = "#{Video.rebuild_queue} videos in queue."
      end
    end
    
    def populate
      try_and do
        @video.pull_meta(params[:source], params[:title], params[:description], params[:tags])
      end
    end
    
    def reprocess
      try_and do
        flash[:notice] = "Processing Video: #{@video.generate_webm}"
      end
    end
    
    def extract_thumbnail
      try_and do
        @video.set_thumbnail(false)
        flash[:notice] = "Thumbnail Reset."
      end
    end
    
    def merge
      try_and do
        if other = Video.where(id: params[:video][:duplicate_id]).first
          @video.merge(current_user, other)
        else
          @video.unmerge
        end
        
        flash[:notice] = "Changes Saved."
      end
    end
    
    def toggle_featured
      if !current_user.is_staff?
        return head 401
      end
      
      if !(@video = Video.where(id: params[:id]).first)
        return head 404
      end
      
      Video.where(featured: true).update_all(featured: false)
      @video.featured = !@video.featured
      
      if @video.featured
        @video.save
        Tag.add_tag('featured video', @video)
      end
      
      render json: {
        added: @video.featured
      }
    end
    
    def toggle_visibility
      if !current_user.is_staff?
        return head 401
      end
      
      if !(@video = Video.where(id: params[:id]).first)
        return head 404
      end
      
      @video.set_hidden(!@video.hidden)
      @video.save
      
      render json: {
        added: @video.hidden
      }
    end
    
    private
    def badly_named_function
      redirect_to action: 'view', controller: 'admin/admin'
      
      if !current_user.is_contributor?
        return flash[:error] = "Access Denied: You can't do that right now."
      end
      
      yield
    end
    
    def try_and
      redirect_to action: "view", id: params[:video][:id]
      
      if !current_user.is_contributor?
        return flash[:error] = "Error: Login required."
      end
      
      if !(@video = Video.where(id: params[:video][:id]).first)
        return flash[:error] = "Error: Video not found."
      end
      
      yield
    end
  end
end
