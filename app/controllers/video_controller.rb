class VideoController < ApplicationController
  def view
    if !(@video = Video.where(id: params[:id].split(/-/)[0]).first)
      render '/layouts/error', locals: { title: 'Nothing to see here!', description: "This is not the video you are looking for." }
      return
    end
    @time = params[:t].to_i || 0
    if !@video.processed && user_signed_in? && current_user.is_admin
      if @video.processing
        alert = "This video is still being processed. All is good."
      end
    end
    if @video.hidden && (!user_signed_in? || @video.user_id != current_user.id)
      render 'layouts/error', locals: { title: 'Content Removed', description: "The video you are trying to access is currently not available." }
      return
    end
    @metadata = {
      type: "video",
      mime: @video.mime,
      title: @video.title,
      description: @video.description,
      url: url_for(action: "view", controller: "video", id: @video.id, only_path: false) + "-" + (@video.safe_title || "untitled-video"),
      embed_url: url_for(action: "view", controller: "embed", only_path: false, id: @video.id),
      cover: url_for(action: "cover", controller: "imgs", only_path: false, id: @video.id) + ".png",
      tags: @video.tags
    }
    @user = @video.user
    @thread = @video.comment_thread
    if !@thread
      @thread = @video.comment_thread = CommentThread.create(user_id: @user.id)
      @video.save
    end
    @order = '1'
    @results = @comments = Pagination.paginate(@thread.get_comments(user_signed_in? && current_user.is_admin), 0, 10, true)
    @queue = @user.queue(@video.id)
    if !@modificationsAllowed = user_signed_in? && current_user.id == @user.id
      @video.views = @video.views + 1
      @video.heat = @video.computeHotness
      @video.save
    end
    if params[:list] || params[:q]
      if params[:q]
        @album = VirtualAlbum.new(params[:q], params[:index].to_i)
      else
        @album = Album.where(id: params[:list]).first
      end
      if @album
        @items = @album.all_items
        @index = params[:index].to_i || (@items.first ? @items.first.index : 0)
        if @index > 0
          @prev_video = @album.get_prev(current_user, @index)
        end
        @next_video = @album.get_next(current_user, @index)
        @album_editable = user_signed_in? && @album.ownedBy(current_user)
      end
    end
  end
  
  def go_next
    if @video = Video.where(id: params[:id].split(/-/)[0]).first
      if params[:list]
        if @album = Album.where(id: params[:list]).first
          @items = @album.album_items.order(:index)
          @index = params[:index].to_i || (@items.first ? @items.first.index : 0)
          if @index > 0
            @prev_video = @album.get_prev(current_user, @index)
          end
          @next_video = @album.get_next(current_user, @index)
          render json: {
            id: @album.album_items.where(index: @index).first.id,
            prev: @prev_video ? ("/view/" + @prev_video.video.id.to_s + "-" + @prev_video.video.safe_title + "?list=" + @album.id.to_s + "&index=" + @prev_video.index.to_s) : nil,
            next: @next_video ? ("/view/" + @next_video.video.id.to_s + "-" + @next_video.video.safe_title + "?list=" + @album.id.to_s + "&index=" + @next_video.index.to_s) : nil,
            title: @video.title,
            artist: @video.user.username,
            audioOnly: @video.audio_only,
            source: @video.id,
            mime: [ @video.file, @video.mime ]
          }
          return
        end
      end
    end
    render status: 404, nothing: true
  end
  
  def upload
    if user_signed_in?
      if ApplicationHelper.read_only && !current_user.is_admin
        render 'layouts/error', locals: { title: 'Access Denied', description: "That feature is currently disabled. Please wait whilst we fix our servers." }
        return
      end
      if current_user.is_admin && params[:user]
        @user = User.where(id: params[:user]).first
      else
        @user = User.where(id: current_user.id).first
      end
      if @user
        @video = Video.new
        return
      end
    end
    render 'layouts/error', locals: { title: 'Access Denied', description: "You can't do that right now." }
  end
    
  def create
    if user_signed_in?
      if ApplicationHelper.read_only && !current_user.is_admin
        error(params[:async], "Access Denied", "That feature is currently disabled.")
        return
      end
      if current_user.is_admin && params[:video][:user_id]
        user = User.by_name_or_id(params[:video][:user_id])
      end
      if !user
        user = current_user
      end
      file = params[:video][:file]
      cover = params[:video][:cover]
      if checkError(params[:async], file && file.size == 0, "Error", "File is empty")
        return
      end
      if checkError(params[:async], cover && cover.content_type.include?('image/') && cover.size == 0, "Error", "Cover file is empty")
        return
      end
      
      if file && (file.content_type.include?('video/') || file.content_type.include?('audio/'))
        if file.content_type.include?('video/') || (cover && cover.content_type.include?('image/'))
          video = params[:video]
          if !video[:tag_string]
            return error(params[:async], "Error", "You need at least one tag.")
          end
          if !video[:title] || video[:title].strip.length == 0
            return error(params[:async], "Error", "You need to specify a title.")
          end
          data = file.read
          if !(checksum = Video.ensure_uniq(data))[:valid]
            return error(params[:async], "Duplication Error", "The uploaded video already exists.")
          end
          ext = File.extname(file.original_filename)
          if ext == ''
            ext = Mimes.ext(file.content_type)
          end
          title = ApplicationHelper.check_and_trunk(video[:title], "Untitled Video")
          title = ApplicationHelper.demotify(title)
          text = ApplicationHelper.demotify(video[:description])
          comments = CommentThread.create(user_id: user, title: title, owner_type: "Video")
          video = user.videos.create(
                  title: title, safe_title: ApplicationHelper.url_safe(title),
                  description: text, html_description: ApplicationHelper.emotify(text),
                  source: video[:source],
                  audio_only: file.content_type.include?('audio/'),
                  file: ext, mime: file.content_type,
                  comment_thread_id: comments.id,
                  upvotes: 0,
                  downvotes: 0,
                  views: 0,
                  hidden: false,
                  processed: false,
                  checksum: checksum[:value]
          )
          comments.owner_id = video.id
          comments.save
          Tag.loadTags(params[:video][:tag_string], video)
          video.save_file(data)
          video.setThumbnail(cover)
          video.save
          video.generateWebM
          if params[:async]
            render json: { result: "success", ref: "/view/" + video.id.to_s }
          else
            redirect_to action: "view", id: video.id
          end
          return
        else
          error(params[:async], "Error", "Cover art is required for audio files.")
          return
        end
      end
    end
    error(params[:async], "Access Denied", "You can't do that right now.")
  end
  
  def update
    if user_signed_in? && video = Video.where(id: params[:id]).first
      if params[:field] == 'tags'
        Tag.loadTags(params[:value], video)
        video.save
        render status: 200, nothing: true
        return
      elsif params[:field] == 'source'
        video.source = params[:value]
        video.save
        render status: 200, nothing: true
        return
      end
      if video.user_id == current_user.id || current_user.is_admin
        value = ApplicationHelper.demotify(params[:value])
        if params[:field] == 'description'
          video.set_description(value)
          video.save
        elsif params[:field] == 'title'
          video.set_title(value)
          video.save
        end
        render status: 200, nothing: true
        return
      end
    end
    render status: 401, nothing: true
  end
  
  def edit
    if user_signed_in?
      video = Video.where(id: params[:id]).first
      if video.user_id == current_user.id || current_user.is_admin
        @video = video
	@user = video.user
      end
    end
  end
  
  def updateCover
    if user_signed_in? && video = Video.where(id: params[:video][:id]).first
      if video.user_id == current_user.id || current_user.is_admin
        if current_user.is_admin && (file = params[:video][:file])
          video.setFile(file)
          video.save
        end
        if params[:erase]
          video.setThumbnail(false)
        elsif cover = params[:video][:cover]
          if cover.content_type.include?('image/')
            video.setThumbnail(cover)
          end
        end
        if params[:async]
          flash[:notice] = "Cover Art change successfully. You may need to reload the page."
          render json: { result: "success", ref: "/view/" + video.id.to_s }
        else
          redirect_to action: "view", id: video.id
        end
        return
      end
    end
    error(params[:async], "Access Denied", "You can't do that right now.")
  end
  
  def download
    if !(@video = Video.where(id: params[:id].split(/-/)[0]).first)
      return render :file => 'public/404.html', :status => :not_found, :layout => false
    end
    if @video.hidden
      return render :file => 'public/502.html', :status => 502, :layout => false
    end
    file = @video.video_path.to_s
    if !File.exists?(file)
      return render :file => 'public/404.html', :status => :not_found, :layout => false
    end
    response.headers['Content-Length'] = File.size(file).to_s
    send_file(file,
        :filename => "#{@video.id}_#{@video.title}_by_#{@video.artists_string}#{@video.file}",
        :type => @video.mime
    )
  end
  
  def list
    @page = params[:page].to_i
    @results = Pagination.paginate(Video.Finder.order(:created_at), @page, 50, true)
    render template: '/view/listing', locals: {type_id: 0, type: 'videos', type_label: 'Video', items: @results}
  end
  
  def page
    @page = params[:page].to_i
    
    if @user = params[:id]
      @results = User.find(@user.to_i).videos.includes(:tags)
      if !user_signed_in? || current_user.id != @user
        @result = @results.where(hidden: false)
      end
      @results = Pagination.paginate(@result.order(:created_at), @page, 8, true)
    else
      @results = Pagination.paginate(Video.Finder.order(:created_at), @page, 50, true)  
    end
    render json: {
      content: render_to_string(partial: '/layouts/video_thumb_h.html.erb', collection: @results.records),
      pages: @results.pages,
      page: @results.page
    }
  end
  
  private
  def nonil(s, defaul)
    if !s
      return defaul
    end
    s = s.strip
    if s == ''
      return defaul
    end
    return s
  end
  
  def error(async, title, message)
    if async
      render plain: title + ":" + message, status: 401
    else
      render 'layouts/error', locals: { title: title, description: message }
    end
  end
  
  def checkError(async, condition, title, message)
    if condition
      error(async, title, message)
    end
    return condition
  end
end
