class AdminController < ApplicationController
  def view
    if !user_signed_in? || !current_user.is_admin
      render 'layouts/error', locals: { title: 'Access Denied', description: "You can't do that right now." }
      return
    end
    @hidden_count = Video.where(hidden: true).count
    @hiddenvideos = Video.where(hidden: true).limit(5*8).reverse_order
    @unprocessed_count = Video.where("(processed IS NULL or processed = ?) AND hidden = false", false).count
    @unprocessed = Video.where("(processed IS NULL or processed = ?) AND hidden = false", false).limit(5*8)
    @users = User.where(last_sign_in_at: Time.zone.now.beginning_of_month..Time.zone.now.end_of_day).limit(100).order(:last_sign_in_at).reverse_order
    @processorStatus = VideoProcessor.status
    @reports_count = Report.includes(:video).where(resolved: nil).count
    @reports = Report.includes(:video).where(resolved: nil).limit(20)
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
    @items = @album.album_items.includes(:direct_user).order(:index)
    @user = @album.user
  end
  
  def artist
    if !user_signed_in? || !current_user.is_admin
      render 'layouts/error', locals: { title: 'Access Denied', description: "You can't do that right now." }
      return
    end
    @user = User.find(params[:id])
  end
  
  def tag
    if !user_signed_in? || !current_user.is_admin
      render 'layouts/error', locals: { title: 'Access Denied', description: "You can't do that right now." }
      return
    end
    @tag = Tag.find(params[:id])
    @prefix = (@tag.tag_type_id > 0 ? @tag.tag_type.prefix : "[none]")
    @user = User.where(tag_id: @tag.id).first
  end
  
  def view_report
    if @report = Report.where(id: params[:id]).first
      if user_signed_in? && (current_user.is_admin || current_user.id == @report.user_id)
        @thread = @report.comment_thread
        @order = '0'
        @results = @comments = Pagination.paginate(@thread.get_comments(true), (params[:page] || -1).to_i, 10, false)
        @video = @report.video
        @user = @report.user
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
      if VideoProcessor.startManager
        flash[:notice] = "Processing Manager restarted. " + VideoProcessor.queue.length.to_s + " videos in queue."
      else
        flash[:notice] = "Processing Manager already active. " + VideoProcessor.queue.length.to_s + " videos in queue."
      end
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
        video.set_hidden(false)
        video.save
      else
        video.set_hidden(true)
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
  
  def verify_integrity
    if user_signed_in? && current_user.is_admin
      if !(Report.where('created_at > ?', Time.zone.now.yesterday.beginning_of_day).first)
        @report = Report.create(user_id: 0, first: "System", other: "Working...", resolved: false)
        @report.comment_thread = CommentThread.create(user_id: 0, title: 'System Integrity Report (' + Time.zone.now.to_s + ')')
        @report.save
        Thread.start {
          begin
            user_component = User.verify_integrity
            video_component = Video.verify_integrity
            @report.other = ""
            @report.other << "User avatars reset: " + user_component[0].to_s
            @report.other << "<br>User banners reset: " + user_component[1].to_s
            @report.other << "<br>Missing video files: " + video_component[0].to_s
            @report.other << "<br>Missing webm files : " + video_component[1].to_s
            if video_component[3] > 0
              @report.other << "<br>Dropped " + video_component[3].to_s + " Damaged webm files"
            end
            if (video_component[3] + video_component[1]) > 0
              @report.other << "<br>" + (video_component[3] + video_component[1]) + " have been scheduled for reprocessing."
            end
            @report.other << "<br>Missing covers : " + video_component[2].to_s
            if video_component[0] > 0
              @report.other << "<br><br>Damaged videos have been removed from public listings until they can be repaired."
            end
          rescue Exception => e
            @report.other << "<br>Check did not complete correctly. <br>" + e.to_s
            puts e
            puts e.backtrace
          ensure
            @report.resolved = nil
            Notification.notify_admins(@report,
              "A system integrity report has been generated", @report.comment_thread.location)
            @report.save
            ActiveRecord::Base.connection.close
          end
        }
        flash[:notice] = "Success! An integrity check has been launched. A report will be generated upon completion."
      else
        flash[:notice] = "Access Denied: You cannot perform an integrity check more than once per day."
      end
    else
      flash[:notice] = "Access Denied: You do not have the required permissions."
    end
    render json: { ref: url_for(action: "view") }
  end
  
  def report
    if @video = Video.where(id: params[:id]).first
      @report = params[:report]
      @report = Report.create({
        video_id: @video.id,
        first: @report[:first],
        source: @report[:source],
        content_type_unrelated: @report[:content_type_unrelated] == '1',
        content_type_offensive: @report[:content_type_offensive] == '1',
        content_type_disturbing: @report[:content_type_disturbing] == '1',
        content_type_explicit: @report[:content_type_explicit] == '1',
        copyright_holder: @report[:copyright_holder],
        subject: @report[:subject],
        other: @report[:other]
      })
      @report.name = @report[:name] || (user_signed_in? ? current_user.username : "")
      if user_signed_in?
        @report.user_id = current_user.id
      end
      @report.comment_thread = CommentThread.create(user_id: @report.user_id, title: "Report: " + @video.title)
      @report.save
      Notification.notify_admins(@report,
         "A new <b>Report</b> has been submitted for <b>" + @video.title + "</b>", @report.comment_thread.location)
      render status: 200, nothing: true
      return
    end
    render status: 401, nothing: true
  end
end
