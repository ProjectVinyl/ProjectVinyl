module Admin
  class VideoController < ApplicationController
    before_action :authenticate_user!

    def view
      if !user_signed_in? || !current_user.is_contributor?
        return render 'layouts/error', locals: { title: 'Access Denied', description: "You can't do that right now." }
      end
      @modifications_allowed = true
      @video = Video.where(id: params[:id]).first
      @user = @video.user
      @tags = @video.tags
    end
    
    def hidden
      @page = params[:page].to_i
      @results = Pagination.paginate(Video.where(hidden: true), @page, 40, true)
      render json: {
        content: render_to_string(partial: 'admin/video/video_thumb_h.html.erb', collection: @results.records),
        pages: @results.pages,
        page: @results.page
      }
    end

    def unprocessed
      @page = params[:page].to_i
      @results = Pagination.paginate(Video.where("(processed IS NULL or processed = ?) AND hidden = false", false), @page, 40, false)
      render json: {
        content: render_to_string(partial: 'admin/video/video_thumb_h.html.erb', collection: @results.records),
        pages: @results.pages,
        page: @results.page
      }
    end
    
    def populate
      if user_signed_in? && current_user.is_contributor?
        if @video = Video.where(id: params[:video][:id]).first
          @video.pull_meta(params[:source], params[:title], params[:description], params[:tags])
        end
      end
      redirect_to action: "view", id: params[:video][:id]
    end
    
    def delete
      if user_signed_in? && current_user.is_contributor?
        if video = Video.where(id: params[:id]).first
          video.remove_self
          flash[:notice] = "1 Item(s) deleted successfully"
        else
          flash[:error] = "Item could not be found"
        end
      else
        flash[:error] = "Access Denied: You can't do that right now."
      end
      redirect_to url_for(action: 'view')
    end
    
    def batch_drop
      if user_signed_in? && current_user.is_admin?
        videos = Video.where(hidden: true)
        videos.each(&:remove_self)
        flash[:notice] = videos.length.to_s + " Item(s) deleted successfully."
      else
        flash[:error] = "Access Denied: You can't do that right now."
      end
      redirect_to url_for(action: 'view')
    end
    
    def reprocess
      if user_signed_in? && current_user.is_contributor?
        if video = Video.where(id: params[:video][:id]).first
          flash[:notice] = "Processing Video: " + video.generate_webm
        end
      end
      redirect_to action: "view", id: params[:video][:id]
    end

    def rebuild_queue
      if user_signed_in? && current_user.is_contributor?
        flash[:notice] = Video.rebuild_queue.to_s + " videos in queue."
      else
        flash[:error] = "Access Denied: You can't do that right now."
      end
      redirect_to url_for(action: 'view')
    end
    
    def extract_thumbnail
      if user_signed_in? && current_user.is_contributor?
        if video = Video.where(id: params[:video][:id]).first
          video.set_thumbnail(false)
          flash[:notice] = "Thumbnail Reset."
        end
      end
      redirect_to action: "view", id: params[:video][:id]
    end
    
    def merge
      if user_signed_in? && current_user.is_staff?
        if video = Video.where(id: params[:video][:id]).first
          if other = Video.where(id: params[:video][:duplicate_id]).first
            video.merge(current_user, other)
          else
            video.unmerge
          end
          flash[:notice] = "Changes Saved."
        end
      end
      redirect_to action: "video", id: params[:video][:id]
    end
  end
end
