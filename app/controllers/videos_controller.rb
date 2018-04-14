class VideosController < ApplicationController
  def show
    if !(@video = Video.where(id: params[:id]).with_likes(current_user).first)
      return render_error(
        title: 'Nothing to see here!',
        description: 'This is not the video you are looking for.'
      )
    end
    
    if @video.duplicate_id > 0
      flash[:alert] = 'The video you are looking for has been marked as a duplicate of the one below.'
      return redirect_to action: 'show', id: @video.duplicate_id
    end
    
    if @video.hidden && (!user_signed_in? || !@video.owned_by(current_user))
      return render_error(
        title: 'Content Removed',
        description: "The video you are trying to access is currently not available."
      )
    end
    
    load_album
    
    @order = '1'
    @time = (params[:t] || params[:resume]).to_i
    @resume = !params[:resume].nil?
    @page = params[:page] ? params[:page].to_i - 1 : 0
    
    @tags = @video.tags
    @user = @video.user
    @thread = @video.comment_thread
    @comments = @thread.get_comments(user_signed_in? && current_user.is_contributor?).with_likes(current_user)
    @comments = Pagination.paginate(@comments, @page, 10, true)
    @queue = @user.queue(@video.id, current_user)
    
    @metadata = {
      type: "video",
      mime: @video.mime,
      title: @video.title,
      description: @video.description,
      url: url_for(action: :show, controller: :videos, id: @video.id, only_path: false) + "-" + (@video.safe_title || "untitled-video"),
      embed_url: url_for(action: :view, controller: "embed/videos", only_path: false, id: @video.id),
      cover: "#{url_for(action: :cover, controller: :imgs, only_path: false, id: @video.id)}.png",
      tags: @tags,
      oembed: @album ? {
        list: @album.id,
        index: @index
      } : {}
    }
    
    if !(@modifications_allowed = user_signed_in? && current_user.id == @user.id)
      @video.views += 1
      @video.compute_hotness.save
    end
  end
    
  def go_next
    load_album
    
    if !@album
      return head :not_found
    end
    
    @video = Video.where(id: params[:id]).first
    
    if @video && @video.duplicate_id > 0
      @video = Video.where(id: @video.duplicate_id).first
    end
    
    if !@video
      return head :not_found
    end
    
    render json: {
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
  
  def new
    if !user_signed_in?
      return render_access_denied
    end
    
    if ApplicationHelper.read_only && !current_user.is_contributor?
      return render_error(
        title: "Read Only",
        description: "That feature is currently disabled."
      )
    end
    
    @user = current_user
    @video = Video.new
  end
  
  def create
    if !user_signed_in?
      return error("Access Denied", "You can't do that right now.")
    end
    
    if ApplicationHelper.read_only && !current_user.is_contributor?
      return error("Read Only", "That feature is currently disabled.")
    end
    
		user = current_user
    video = params[:video]
    
    file = video[:file]
    cover = video[:cover]
    
    if !file || file.size == 0
      return error("Error", "File is empty")
    end
    
    if !file.content_type.include?('video/') && !file.content_type.include?('audio/')
      return error("Error", "Mismatched content type: '#{file.content_type}'" )
    end
    
    if file.content_type.include?('audio/')
      if !cover || cover.size == 0 || !cover.content_type.include?('image/')
        return error("Error", "Cover art is required for audio files.")
      end
    end
    
    if video[:tag_string].blank?
      return error("Error", "You need at least one tag.")
    end
    
    data = file.read
    if !(checksum = Video.ensure_uniq(data))[:valid]
      return error(params[:format] == 'json', "Duplication Error", "The uploaded video already exists.")
    end
    
    ext = File.extname(file.original_filename)
    if ext.blank?
      ext = Mimes.ext(file.content_type)
    end
    
    title = StringsHelper.check_and_trunk(video[:title], "Untitled Video")
    
    Video.transaction do
      @video = user.videos.create(
        title: title,
        safe_title: PathHelper.url_safe(title),
        description: video[:description],
        html_description: BbcodeHelper.emotify(video[:description]),
        source: Video.clean_url(video[:source]),
        audio_only: file.content_type.include?('audio/'),
        file: ext,
        mime: file.content_type,
        upvotes: 0, downvotes: 0, views: 0, duplicate_id: 0,
        hidden: false, processed: false,
        checksum: checksum[:value]
      )
      
      @comments = @video.comment_thread = CommentThread.create(user_id: user, title: title)
      @comments.save
      
      if current_user.subscribe_on_upload?
        @comments.subscribe(current_user)
      end
      
      if @video.source && !@video.source.blank?
        TagHistory.record_source_changes(@video, current_user.id)
      else
        video[:tag_string] = Tag.append_tag_strings(video[:tag_string], 'source needed')
      end
      
      Tag.load_tags(video[:tag_string], @video)
    end
    
    @video.video = data
    @video.set_thumbnail(cover, video[:time])
    @video.save
    
    if params[:format] == 'json'
      return render json: {
        result: "success",
        ref: @video.link
      }
    end
    redirect_to action: :view, id: @video.id
  end
	
  def update
    if !user_signed_in?
      return head 401
    end
    
    if !(video = Video.where(id: params[:id]).first)
      return head :not_found
    end
    
    if !video.owned_by(current_user)
			return head 401
		end
		
		if params[:field] == 'description'
			video.set_description(params[:value])
			render json: { content: video.html_description }
		elsif params[:field] == 'title'
			video.set_title(params[:value])
			render json: { content: video.title }
		end
    
    video.save
		
  end
  
	def details
		if !user_signed_in?
      return head 401
    end
		
		if !(video = Video.where(id: params[:video_id]).first)
      return head :not_found
    end
		
		if changes = Tag.load_tags(params[:tags], video)
			TagHistory.record_tag_changes(changes[0], changes[1], video.id, current_user.id)
		end
		
		if video.source != params[:source]
			video.set_source(params[:source])
			TagHistory.record_source_changes(video, current_user.id)
		end
		
		video.save
		
		head :ok
	end
	
  def edit
    if !user_signed_in?
      return render_access_denied
    end
    
    if !(@video = Video.where(id: params[:id]).first)
      return render_error(
        title: 'Nothing to see here!',
        description: 'This is not the video you are looking for.'
      )
    end
    
    if !@video.owned_by(current_user)
      return render_access_denied
    end
    
    @user = @video.user
  end
  
  def cover
    if !user_signed_in?
      error(params[:format] == 'json', "Access Denied", "You can't do that right now.")
    end
    
    if !(video = Video.where(id: params[:video_id]).first)
      error(params[:format] == 'json', "Nothing to see here!", "This is not the video you are looking for.")
    end
    
    if !video.owned_by(current_user)
      error(params[:format] == 'json', "Access Denied", "You can't do that right now.")
    end
    
    if current_user.is_staff? && (file = params[:video][:file])
      video.set_file(file)
    end
    
    cover = params[:video][:cover] || !params[:erase]
    video.set_thumbnail(cover, params[:video][:time])
    
    video.save
    
    flash[:notice] = "Changes saved successfully. You may need to refresh the page."
    if params[:format] == 'json'
      return render json: {
        result: "success",
        ref: video.ref
      }
    end
    
    redirect_to action: "view", id: video.id
  end
  
  def download
    if !(@video = Video.where(id: params[:video_id]).first)
      return not_found
    end
    
    if @video.duplicate_id > 0
      @video = Video.where(id: @video.duplicate_id).first
    end
    
    if @video.hidden && !(user_signed_in? && @video.owned_by(current_user))
      return forbidden
    end
    
    file = @video.video_path.to_s
    if !File.exist?(file)
      return not_found
    end
    
    response.headers['Content-Length'] = File.size(file).to_s
    send_file(file,
      filename: "#{@video.id}_#{@video.title}_by_#{@video.artists_string}#{@video.file}",
      type: @video.mime
    )
  end
  
  def index
    by_type do |is_admin, results|
      render_listing_total results.with_likes(current_user).order(:created_at), params[:page].to_i, 50, true, {
        is_admin: is_admin, table: 'videos', label: 'Video'
      }
    end
  end
  
  def like
    check_then do |video|
      video.upvote(current_user, params[:incr])
    end
  end
  
  def dislike
    check_then do |video|
      video.downvote(current_user, params[:incr])
    end
  end
  
  def star
    check_then do |video|
      video.star(current_user)
    end
  end
  
  private
  def by_type
    if user_signed_in? && current_user.is_contributor?
      if params[:merged]
        @data = 'merged=1'
        return yield(true, Video.where.not(duplicate_id: 0))
      elsif params[:unlisted]
        @data = 'unlisted=1'
        return yield(true, Video.where(hidden: true))
      end
    end
    
    yield(false, Video.finder)
  end
  
  def load_album
    if params[:list] || params[:q]
      if params[:q]
        @album = VirtualAlbum.new(params[:q], params[:index].to_i)
      else
        @album = Album.where(id: params[:list]).first
      end
      
      if @album
        @items = params[:q] ? @album.album_items : @album.album_items.order(:index)
        @index = params[:index].to_i || (@items.first ? @items.first.index : 0)
        
        if @index > 0
          @prev_video = @album.get_prev(current_user, @index)
        end
        
        @next_video = @album.get_next(current_user, @index)
        
        @album_editable = user_signed_in? && @album.owned_by(current_user)
      end
    end
  end
  
  def check_then
    if !user_signed_in?
      return head 401
    end
    
    if !(video = Video.where(id: params[:video_id]).first)
      return head :not_found
    end
    
    return render json: {
      count: yield(video)
    }
  end
end
