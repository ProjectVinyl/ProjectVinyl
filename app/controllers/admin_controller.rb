class AdminController < ApplicationController
  def view
    if !user_signed_in? || !current_user.is_contributor?
      render 'layouts/error', locals: { title: 'Access Denied', description: "You can't do that right now." }
      return
    end
    @hiddenvideos = Pagination.paginate(Video.where(hidden: true), 0, 40, true)
    @unprocessed = Pagination.paginate(Video.where("(processed IS NULL or processed = ?) AND hidden = false", false), 0, 40, false)
    @users = User.where('last_sign_in_at > ? OR updated_at > ?', Time.zone.now.beginning_of_month, Time.zone.now.beginning_of_month).limit(100).order(:last_sign_in_at).reverse_order
    @processorStatus = VideoProcessor.status
    @reports_count = Report.includes(:video).where(resolved: nil).count
    @reports = Report.includes(:video).where(resolved: nil).limit(20)
  end
  
  def files
    render_path(params, false)
  end
  
  def morefiles
    render_path(params, true)
  end
  
  def render_path(params, ajax)
    if !user_signed_in? || !current_user.admin?
      if ajax
        return render status: 403, nothing: true
      end
      return render file: '/public/403.html', layout: false
    end
    @location = (params[:p] || "public/stream").strip
    if @location == ''
      @location = ['public']
    else
      @location = @location.split(/\/|\\/)
    end
    if @location.length == 0 && @location[0] != 'encoding'
      @location = [ 'public' ] + @location
    end
    if @location.length > 1 && @location[1] != 'stream' && @location[1] != 'cover'
      if @location[0] != 'encoding'
        if ajax
          return render status: 403, nothing: true
        end
        return render file: '/public/403.html', layout: false
      end
    end
    begin
      @location = @location.join('/')
      @public = VideoDirectory.Entries(@location).limit(50)
      if params[:start] && !@public.start_from(params[:start], params[:offset]) && ajax
        return render json: {}
      end
      if params[:end] && !@public.end_with(params[:end]) && ajax
        return render json: {}
      end
      if @location == 'public'
        @public.filter do |loc|
          name = loc.split('.')[0]
          loc.index('.').nil? && (name == 'stream' || name == 'cover')
        end
      end
      @public.names_resolver do |names,ids|
        Video.where('id IN (' + ids.join(',') + ')').pluck(:id,:title).each do |i|
          names[i[0].to_s] = i[1]
        end
      end
    rescue Exception => e
      if ajax
        return render status: 404, nothing: true
      end
      render file: '/public/404.html', layout: false
    end
    if ajax
      render json: {
        :content => render_to_string(partial: '/admin/file.html.erb', collection: @public.items),
        :start => @public.start_ref,
        :end => @public.end_ref
      }
    end
  end
  
  def page_hidden
    @page = params[:page].to_i
    @results = Pagination.paginate(Video.where(hidden: true), @page, 40, true)
    render json: {
      content: render_to_string(partial: '/admin/video_thumb_h.html.erb', collection: @results.records),
      pages: @results.pages,
      page: @results.page
    }
  end
  
  def page_unprocessed
    @page = params[:page].to_i
    @results = Pagination.paginate(Video.where("(processed IS NULL or processed = ?) AND hidden = false", false), @page, 40, false)
    render json: {
      content: render_to_string(partial: '/admin/video_thumb_h.html.erb', collection: @results.records),
      pages: @results.pages,
      page: @results.page
    }
  end
  
  def video
    if !user_signed_in? || !current_user.is_contributor?
      render 'layouts/error', locals: { title: 'Access Denied', description: "You can't do that right now." }
      return
    end
    @modificationsAllowed = true
    @video = Video.where(id: params[:id]).first
    @user = @video.user
    @tags = @video.tags
  end
  
  def album
    if !user_signed_in? || !current_user.is_contributor?
      render 'layouts/error', locals: { title: 'Access Denied', description: "You can't do that right now." }
      return
    end
    @modificationsAllowed = true
    @album = Album.find(params[:id])
    @items = Pagination.paginate(@album.ordered(@album.album_items.includes(:direct_user)), 0, 50, false)
    @user = @album.user
  end
  
  def artist
    if !user_signed_in? || !current_user.is_contributor?
      render 'layouts/error', locals: { title: 'Access Denied', description: "You can't do that right now." }
      return
    end
    @user = User.find(params[:id])
  end
  
  def tag
    if !user_signed_in? || !current_user.is_contributor?
      render 'layouts/error', locals: { title: 'Access Denied', description: "You can't do that right now." }
      return
    end
    @tag = Tag.find(params[:id])
    @prefix = (@tag.tag_type_id && @tag.tag_type_id > 0 ? @tag.tag_type.prefix : "[none]")
    @user = User.where(tag_id: @tag.id).first
  end
  
  def view_report
    if @report = Report.where(id: params[:id]).first
      if user_signed_in? && (current_user.is_contributor? || current_user.id == @report.user_id)
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
    if user_signed_in? && current_user.is_contributor?
      if (user = User.by_name_or_id(params[:item][:user_id]))
        if params[:type] == 'video'
          item = Video.where(id: params[:item][:id]).first
        elsif params[:type] == 'album'
          item = Album.where(id: params[:item][:id]).first
        end
        if item
          item.transferTo(user)
          return redirect_to action: params[:type], id: params[:item][:id]
        end
      else
        flash[:alert] = "Error: Destination user was not found."
        return redirect_to action: params[:type], id: params[:item][:id]
      end
    end
    render status: 401, nothing: true
  end
  
  def deleteVideo
    if user_signed_in? && current_user.is_contributor?
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
    if user_signed_in? && current_user.is_contributor?
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
  
  def reprocessVideo
    if user_signed_in? && current_user.is_contributor?
      if video = Video.where(id: params[:video][:id]).first
        flash[:notice] = "Processing Video: " + video.generateWebM()
      end
    end
    redirect_to action: "video", id: params[:video][:id]
  end
  
  def rebuildQueue
    if user_signed_in? && current_user.is_contributor?
      flash[:notice] = Video.rebuild_queue.to_s + " videos in queue."
    else
      flash[:error] = "Access Denied: You can't do that right now."
    end
    render json: { ref: url_for(action: "view") }
  end
  
  def batch_preprocessVideos
    if user_signed_in? && current_user.is_contributor?
      if VideoProcessor.startManager
        flash[:notice] = "Processing Manager restarted. " + VideoProcessor.queue.length.to_s + " videos in queue."
      else
        flash[:notice] = "Processing Manager already active. " + VideoProcessor.queue.length.to_s + " videos in queue."
      end
    end
    render json: { ref: url_for(action: "view") }
  end
  
  def batch_dropVideos
    if user_signed_in? && current_user.is_admin?
      videos = Video.where(hidden: true)
      videos.each do |video|
        video.removeSelf
      end
      flash[:notice] = videos.length.to_s + " Item(s) deleted successfully."
    else
      flash[:error] = "Access Denied: You can't do that right now."
    end
    render json: { ref: url_for(action: "view") }
  end
  
  
  def extractThumbnail
    if user_signed_in? && current_user.is_contributor?
      if video = Video.where(id: params[:video][:id]).first
        video.setThumbnail(false)
        flash[:notice] = "Thumbnail Reset."
      end
    end
    redirect_to action: "video", id: params[:video][:id]
  end
  
  def visibility
    if user_signed_in? && current_user.is_contributor?
      if video = Video.where(id: params[:id]).first
        video.set_hidden(!video.hidden)
        video.save
      end
      return render json: { :added => video.hidden }
    end
    render status: 401, nothing: true
  end
  
  def role
    if user_signed_in? && current_user.is_staff?
      if params[:id].to_i != current_user.id && user = User.where(id: params[:id]).first
        role = Roleable.role_for(params[:role])
        if role <= current_user.role
          user.role = role
          user.save
        end
        return render json: {
          admin: user.admin?,
          contributor: user.contributor?,
          staff: user.staff?,
          normal: user.role == 0,
          banned: user.banned?
        }
      end
    end
    render status: 401, nothing: true
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
  
  def togglebadge
    if user_signed_in? && current_user.is_contributor?
      if user = User.where(id: params[:id]).first
        if existing = user.user_badges.where(badge_id: params[:badge_id]).first
          existing.destroy
          render json: { :added => false }
        elsif badge = Badge.where(id: params[:badge_id]).first
          if badge.badge_type > 0 && params[:extra]
            user.user_badges.create(badge_id: badge.id, custom_title: params[:extra])
          else
            user.user_badges.create(badge_id: badge.id)
          end
          render json: { :added => true }
        end
      end
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
    if user_signed_in? && current_user.is_admin?
      if !(Report.where('created_at > ?', Time.zone.now.yesterday.beginning_of_day).first)
        @report = Report.create(user_id: 0, first: "System", other: "Working...", resolved: false)
        @report.comment_thread = CommentThread.create(user_id: 0, title: 'System Integrity Report (' + Time.zone.now.to_s + ')')
        @report.save
        Thread.start {
          begin
            user_component = User.verify_integrity
            @report.other = ""
            @report.other << "User avatars reset: " + user_component[0].to_s
            @report.other << "<br>User banners reset: " + user_component[1].to_s
            @report.save
            Video.verify_integrity(@report)
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
