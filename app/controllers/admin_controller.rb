class AdminController < ApplicationController
  def view
    if !user_signed_in? || !current_user.is_admin
      render 'layouts/error', locals: { title: 'Access Denied', description: "You can't do that right now." }
      return
    end
    @hiddenvideos = Video.where(hidden: true).limit(5*8).reverse_order
    @unprocessed_count = Video.where("processed IS NULL or processed = ?", false).count
    @unprocessed = Video.where("processed IS NULL or processed = ?", false).limit(5*8)
    @users = User.where(last_sign_in_at: Time.zone.now.beginning_of_month..Time.zone.now.end_of_day).limit(100).order(:last_sign_in_at).reverse_order
    @processorStatus = VideoProcessor.status
  end
  
  def video
    if !user_signed_in? || !current_user.is_admin
      render 'layouts/error', locals: { title: 'Access Denied', description: "You can't do that right now." }
      return
    end
    @modificationsAllowed = true
    @video = Video.where(id: params[:id]).first
    @user = @video.user
  end
  
  def album
    if !user_signed_in? || !current_user.is_admin
      render 'layouts/error', locals: { title: 'Access Denied', description: "You can't do that right now." }
      return
    end
    @modificationsAllowed = true
    @album = Album.find(params[:id])
    @items = @album.album_items.include(:artist)
  end
  
  def artist
    if !user_signed_in? || !current_user.is_admin
      render 'layouts/error', locals: { title: 'Access Denied', description: "You can't do that right now." }
      return
    end
    @user = User.find(params[:id])
  end
  
  def view_report
    if @report = Report.where(id: params[:id]).first
      if user_signed_in? && (current_user.is_admin || current_user.id == @report.user_id)
        @thread = @report.comment_thread
        @order = '0'
        @results = @comments = Pagination.paginate(@thread.get_comments, (params[:page] || -1).to_i, 10, false)
        @video = Video.where(id: params[:id]).first
        @user = @video.user
        return
      end
    end
    render 'layouts/error', locals: { title: 'Access Denied', description: "You can't do that right now." }
  end
  
  def transferItem
    if user_signed_in? && current_user.is_admin
      if (user = User.by_name_or_id(params[:item][:user_id]))
        if params[:type] == 'video'
          item = Video.where(id: params[:item][:id]).first
        elsif params[:type] == 'album'
          item = Album.where(id: params[:item][:id]).first
        end
        if item
          item.transferTo(user)
          redirect_to action: params[:type], id: params[:item][:id]
          return
        end
      end
    end
    render status: 401, nothing: true
  end
  
  def deleteVideo
    if user_signed_in? && current_user.is_admin
      if video = Video.where(id: params[:id]).first
        video.removeSelf
        flash[:notice] = "1 Item(s) deleted successfully"
      else
        flash[:error] = "Item could not be found"
      end
    else
      flash[:error] = "Access Denied: You can't do that right now."
    end
    render json: { ref: url_for(action: "view") }
  end
  
  def deleteAlbum
    if user_signed_in? && current_user.is_admin
      if album = Album.where(id: params[:id]).first
        album.destroy
        flash[:notice] = "1 Item(s) deleted successfully."
      else
        flash[:error] = "Item could not be found."
      end
    else
      flash[:error] = "Access Denied: You can't do that right now."
    end
    render json: { ref: url_for(action: "view") }
  end
  
  def deleteArtist
    if user_signed_in? && current_user.is_admin
      if artist = Artist.where(id: params[:id]).first
        albums = artist.albums.count
        videos = artist.videos.count
        artist.removeSelf
        flash[:notice] = (albums + videos + 1).to_s + " Item(s) deleted successfully."
      else
        flash[:error] = "Item could not be found."
      end
    else
      flash[:error] = "Access Denied: You can't do that right now."
    end
    render json: { ref: url_for(action: "view") }
  end
  
  def reprocessVideo
    if user_signed_in? && current_user.is_admin
      if video = Video.where(id: params[:video][:id]).first
        flash[:notice] = "Processing Video: " + video.generateWebM()
      end
    end
    redirect_to action: "video", id: params[:video][:id]
  end
  
  def batch_preprocessVideos
    if user_signed_in? && current_user.is_admin
      videos = Video.where(processed: nil)
      videos.each do |video|
        video.generateWebM()
      end
      if videos.length > 0
        VideoProcessor.startManager
      end
      flash[:notice] = videos.length.to_s + " videos queued."
    end
    render json: { ref: url_for(action: "view") }
  end
  
  def extractThumbnail
    if user_signed_in? && current_user.is_admin
      if video = Video.where(id: params[:video][:id]).first
        video.setThumbnail(false)
        flash[:notice] = "Thumbnail Reset."
      end
    end
    redirect_to action: "video", id: params[:video][:id]
  end
  
  def visibility
    if user_signed_in? && current_user.is_admin
      video = Video.find(params[:video][:id])
      if video.hidden
        video.hidden = false
        video.save
      else
        video.hidden = true
        video.save
      end
      redirect_to action: 'video', id: params[:video][:id]
      return
    end
    render status: 401, nothing: true
  end
  
  def reporter
    @video = Video.where(id: params[:id]).first
    if @video
      render json: {
        content: render_to_string(partial: '/layouts/reporter', locals: { video: @video, report: Report.new })
      }
      return
    end
    render status: 401, nothing: true
  end
    
  def report
    if @video = Video.where(id: params[:id]).first
      @recievers = User.where(is_admin: true).pluck(:id)
      @report = params[:report]
      @report = Report.create({
        video_id: @video.id,
        first: @report[:first],
        source: @report[:source],
        content_type_unrelated: @report[:content_type_unrelated] == '1',
        content_type_offensive: @report[:content_type_offensive] == '1',
        content_type_unrelated: @report[:content_type_unrelated] == '1',
        content_type_unrelated: @report[:content_type_explicit] == '1',
        copyright_holder: @report[:copyright_holder],
        subject: @report[:subject],
        other: @report[:other]
      })
      @report.name = @report[:name] || (user_signed_in? ? current_user.username : "")
      if user_signed_in?
        @report.user_id = current_user.id
      end
      @report.comment_thread = CommentThread.create(title: "Report: " + @video.title)
      @report.save
      Notification.notify_recievers(@recievers, @report,
         "A new <b>Report</b> has been submitted for <b>" + @video.title + "</b>", @report.comment_thread)
      render status: 200, nothing: true
      return
    end
    render status: 401, nothing: true
  end
end
