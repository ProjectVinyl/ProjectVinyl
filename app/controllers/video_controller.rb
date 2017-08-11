class VideoController < ApplicationController
  def view
    if !(@video = Video.where(id: params[:id]).first)
      return render_error(
        title: 'Nothing to see here!',
        description: 'This is not the video you are looking for.'
      )
    end
    
    if @video.duplicate_id > 0
      flash[:alert] = 'The video you are looking for has been marked as a duplicate of the one below.'
      return redirect_to action: 'view', id: @video.duplicate_id
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
        @prev_video = @album.get_prev(current_user, @index) if @index > 0
        @next_video = @album.get_next(current_user, @index)
        @album_editable = user_signed_in? && @album.owned_by(current_user)
      end
    end
    @time = (params[:t] || params[:resume] || 0).to_i
    @resume = !params[:resume].nil?
    if @video.hidden && (!user_signed_in? || @video.user_id != current_user.id)
      return render_error(
        title: 'Content Removed',
        description: "The video you are trying to access is currently not available."
      )
    end
    @tags = @video.tags
    @metadata = {
      type: "video",
      mime: @video.mime,
      title: @video.title,
      description: @video.description,
      url: url_for(action: "view", controller: "video", id: @video.id, only_path: false) + "-" + (@video.safe_title || "untitled-video"),
      embed_url: url_for(action: "view", controller: "embed/video", only_path: false, id: @video.id),
      cover: url_for(action: "cover", controller: "imgs", only_path: false, id: @video.id) + ".png",
      tags: @tags,
      oembed: @album ? { list: @album.id, index: @index } : {}
    }
    @user = @video.user
    @thread = @video.comment_thread
    @order = '1'
    @page = params[:page] ? params[:page].to_i - 1 : 0
    @comments = Pagination.paginate(@thread.get_comments(user_signed_in? && current_user.is_contributor?), @page, 10, true)
    @queue = @user.queuev2(@video.id)
    if !(@modifications_allowed = user_signed_in? && current_user.id == @user.id)
      @video.views += 1
      @video.compute_hotness.save
    end
  end

  def go_next
    if @video = Video.where(id: params[:id].split(/-/)[0]).first
      if @video.duplicate_id > 0
        @video = Video.where(id: @video.duplicate_id).first
      end
      if params[:list]
        if @album = Album.where(id: params[:list]).first
          @items = @album.album_items.order(:index)
          @index = params[:index].to_i || (@items.first ? @items.first.index : 0)
          @prev_video = @album.get_prev(current_user, @index) if @index > 0
          @next_video = @album.get_next(current_user, @index)
          return render json: {
            id: @album.album_items.where(index: @index).first.id,
            prev: @prev_video ? @prev_video.link : nil,
            next: @next_video ? @next_video.link : nil,
            title: @video.title,
            artist: @video.user.username,
            audioOnly: @video.audio_only,
            source: @video.id,
            mime: [@video.file, @video.mime]
          }
        end
      end
    end
    head 404
  end
  
  def new
    if !user_signed_in?
      return render_error(
        title: 'Access Denied',
        description: "You can't do that right now."
      )
    end
    if ApplicationHelper.read_only && !current_user.is_contributor?
      return render_error(
        title: 'Access Denied',
        description: "That feature is currently disabled. Please wait whilst we fix our servers."
      )
    end
    @user = current_user
    @video = Video.new
  end
  
  def create
    if user_signed_in?
      if ApplicationHelper.read_only && !current_user.is_contributor?
        return error(params[:async], "Access Denied", "That feature is currently disabled.")
      end
      if current_user.is_contributor? && params[:video][:user_id]
        user = User.by_name_or_id(params[:video][:user_id])
      end
      user = current_user if !user
      file = params[:video][:file]
      cover = params[:video][:cover]
      if check_error(params[:async], file && file.size == 0, "Error", "File is empty")
        return
      end
      if check_error(params[:async], cover && cover.content_type.include?('image/') && cover.size == 0, "Error", "Cover file is empty")
        return
      end
      
      if file && (file.content_type.include?('video/') || file.content_type.include?('audio/'))
        if file.content_type.include?('video/') || (cover && cover.content_type.include?('image/'))
          video = params[:video]
          if video[:tag_string].blank?
            return error(params[:async], "Error", "You need at least one tag.")
          end
          if video[:title].blank?
            return error(params[:async], "Error", "You need to specify a title.")
          end
          data = file.read
          if !(checksum = Video.ensure_uniq(data))[:valid]
            return error(params[:async], "Duplication Error", "The uploaded video already exists.")
          end
          ext = File.extname(file.original_filename)
          ext = Mimes.ext(file.content_type) if ext == ''
          title = ApplicationHelper.check_and_trunk(video[:title], "Untitled Video")
          title = ApplicationHelper.demotify(title)
          text = ApplicationHelper.demotify(video[:description])
          Video.transaction do
            @video = user.videos.create(
              title: title, safe_title: ApplicationHelper.url_safe(title),
              description: text, html_description: ApplicationHelper.emotify(text),
              source: Video.clean_url(video[:source]),
              audio_only: file.content_type.include?('audio/'),
              file: ext,
              mime: file.content_type,
              upvotes: 0,
              downvotes: 0,
              views: 0,
              hidden: false,
              processed: false,
              checksum: checksum[:value],
              duplicate_id: 0
            )
            if @video.source && @video.source.strip != ''
              TagHistory.record_source_change(current_user, @video, @video.source)
            else
              if !params[:video][:tag_string]
                params[:video][:tag_string] = ''
              elsif params[:video][:tag_string].strip != ''
                params[:video][:tag_string] << ','
              end
              params[:video][:tag_string] << 'source needed'
            end
            @comments = @video.comment_thread = CommentThread.create(user_id: user, title: title)
            @comments.save
            if current_user.subscribe_on_upload?
              @comments.subscribe(current_user)
            end
          end
          @video.save_file(data)
          if params[:video][:time] && (time = params[:video][:time].to_f) >= 0
            @video.set_thumbnail_time(time)
          else
            @video.set_thumbnail(cover)
          end
          Tag.load_tags(params[:video][:tag_string], @video)
          @video.save
          if params[:async]
            return render json: { result: "success", ref: "/view/" + @video.id.to_s }
          end
          return redirect_to action: "view", id: @video.id
        else
          return error(params[:async], "Error", "Cover art is required for audio files.")
        end
      end
    end
    error(params[:async], "Access Denied", "You can't do that right now.")
  end
  
  def patch
    if user_signed_in? && video = Video.where(id: params[:id]).first
      if params[:field] == 'tags'
        if changes = Tag.load_tags(params[:value], video)
          TagHistory.record_changes(current_user, video, changes[0], changes[1])
        end
        video.save
        return head 200
      elsif params[:field] == 'source'
        if video.source != params[:value]
          video.set_source(params[:value])
          video.save
          TagHistory.record_source_change(current_user, video, video.source)
        end
        return head 200
      end
      if video.user_id == current_user.id || current_user.is_contributor?
        value = ApplicationHelper.demotify(params[:value])
        if params[:field] == 'description'
          video.set_description(value)
          video.save
        elsif params[:field] == 'title'
          video.set_title(value)
          video.save
        end
        return head 200
      end
    end
    head 401
  end
  
  def edit
    if !user_signed_in? || !(@video = Video.where(id: params[:id]).first) || (@video.user_id != current_user.id && !current_user.is_contributor?)
      return render_error(
        title: 'Access Denied',
        description: "You can't do that right now."
      )
    end
    @user = @video.user
  end
  
  def update_cover
    if user_signed_in? && video = Video.where(id: params[:video][:id]).first
      if video.user_id == current_user.id || current_user.is_contributor?
        if current_user.is_staff? && (file = params[:video][:file])
          video.set_file(file)
          video.save
        end
        if cover = params[:video][:cover]
          video.set_thumbnail(cover) if cover.content_type.include?('image/')
        elsif (time = params[:video][:time].to_f) >= 0
          video.set_thumbnail_time(time)
        elsif params[:erase] || file
          video.set_thumbnail(false)
        end
        flash[:notice] = "Changes saved successfully. You may need to refresh the page."
        if params[:async]
          return render json: { result: "success", ref: "/view/" + video.id.to_s }
        end
        return redirect_to action: "view", id: video.id
      end
    end
    error(params[:async], "Access Denied", "You can't do that right now.")
  end
  
  def download
    if !(@video = Video.where(id: params[:id].split(/-/)[0]).first)
      return render file: 'public/404.html', status: :not_found, layout: false
    end
    if @video.duplicate_id > 0
      @video = Video.where(id: @video.duplicate_id).first
    end
    if @video.hidden && (!user_signed_in? || (current_user.id != @video.user_id && !current_user.is_contributor?))
      return render file: 'public/401.html', status: 401, layout: false
    end
    file = @video.video_path.to_s
    if !File.exist?(file)
      return render file: 'public/404.html', status: 404, layout: false
    end
    response.headers['Content-Length'] = File.size(file).to_s
    send_file(
      file,
      filename: "#{@video.id}_#{@video.title}_by_#{@video.artists_string}#{@video.file}",
      type: @video.mime
    )
  end
  
  def index
    @page = params[:page].to_i
    type = 0
    merged = user_signed_in? && current_user.is_contributor?
    if merged && params[:merged]
      @results = Video.where.not(duplicate_id: 0)
      @data = 'merged=1'
      type = -1
    elsif merged && params[:unlisted]
      @results = Video.where(hidden: true)
      @data = 'unlisted=1'
      type = -1
    else
      @results = Video.finder
    end
    
    render_listing @results.order(:created_at), @page, 50, true, {
      id: type, table: 'videos', label: 'Video'
    }
  end
  
  def page
    @page = params[:page].to_i
    if @user = params[:id]
      @results = User.find(@user.to_i).videos.includes(:tags)
      if !user_signed_in? || current_user.id != @user.to_i
        @results = @results.listable
      else
        @results = @results.where(duplicate_id: 0)
      end
      @page_size = 8
    else
      merged = user_signed_in? && current_user.is_contributor?
      if (merged &= params[:merged])
        @results = Video.where.not(duplicate_id: 0)
      elsif (merged &= params[:unlisted])
        @results = Video.where(hidden: true)
      else
        @results = Video.finder
      end
      @page_size = 50
    end
    @results = @results.order(:created_at)
    partial = merged ? 'admin/video/thumb_h' : 'video/thumb_h'
    render_pagination partial, @results, @page, @page_size, true
  end
  
  def upvote
    if user_signed_in? && (video = Video.where(id: params[:id]).first)
      return render json: {
        count: video.upvote(current_user, params[:incr])
      }
    end
    head 401
  end
  
  def downvote
    if user_signed_in? && (video = Video.where(id: params[:id]).first)
      return render json: {
        count: video.downvote(current_user, params[:incr])
      }
    end
    head 401
  end
  
  def star
    if user_signed_in? && (video = Video.where(id: params[:id]).first)
      return render json: {
        added: video.star(current_user)
      }
    end
    head 401
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
end
