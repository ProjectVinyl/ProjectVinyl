class VideoController < ApplicationController
  def view
    if @video = Video.where(id: params[:id].split(/-/)[0]).first
      @time = params[:t].to_i || 0
      if !@video.processed && user_signed_in? && current_user.is_admin
        if @video.processing
          alert = "This video is still being processed. All is good."
        end
      end
      if @video.hidden && (!user_signed_in? || @video.artist_id != current_user.artist_id)
        render 'layouts/error', locals: { title: 'Content Removed', description: "The video you are trying to access is currently not available." }
        return
      end
      @metadata = {
        type: "video",
        mime: @video.mime,
        title: @video.title,
        description: @video.description,
        url: url_for(action: "view", controller: "video", id: @video.id, only_path: false) + "-" + ApplicationHelper.url_safe(@video.title),
        embed_url: url_for(action: "view", controller: "embed", only_path: false, id: @video.id),
        cover: url_for(action: "cover", controller: "imgs", only_path: false, id: @video.id),
        tags: @video.genres
      }
      @artist = @video.artist
      @queue = @artist.videos.where(hidden: false).where.not(id: @video.id).order("RAND()").limit(7)
      if !@modificationsAllowed = user_signed_in? && current_user.artist_id == @artist.id
        @video.views = @video.views + 1
        @video.save
      end
      if params[:list]
        if @album = Album.where(id: params[:list]).first
          @items = @album.album_items.order(:index)
          @index = params[:index].to_i || (@items.first ? @items.first.index : 0)
          if @index > 0
            @prev_video = @items.where(index: @index - 1).first
          end
          @next_video = @items.where(index: @index + 1).first
          @album_editable = user_signed_in? && @album.ownedBy(current_user)
        end
      end
    end
  end
  
  def go_next
    if @video = Video.where(id: params[:id].split(/-/)[0]).first
      if params[:list]
        if @album = Album.where(id: params[:list]).first
          @items = @album.album_items.order(:index)
          @index = params[:index].to_i || (@items.first ? @items.first.index : 0)
          @next_video = @items.where(index: @index + 1).first
          render json: {
            id: @album.album_items.where(index: @index).first.id,
            next: @prev_video ? ("/view/" + @prev_video.video.id.to_s + "-" + ApplicationHelper.url_safe(@prev_video.video.title) + "?list=" + @album.id.to_s + "&index=" + @prev_video.index.to_s) : nil,
            prev: @next_video ? ("/view/" + @next_video.video.id.to_s + "-" + ApplicationHelper.url_safe(@next_video.video.title) + "?list=" + @album.id.to_s + "&index=" + @next_video.index.to_s) : nil,
            title: @video.title,
            artist: @video.artist.name,
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
      if current_user.is_admin && params[:artist]
        @artist = Artist.where(id: params[:artist]).first
      else
        @artist = Artist.where(id: current_user.artist_id).first
      end
      if @artist
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
      if current_user.is_admin && params[:video][:artist_id]
        artist = Artist.by_name_or_id(params[:video][:artist_id])
        puts artist
      end
      if !artist
        artist = Artist.where(id: current_user.artist_id).first
        puts artist
      end
      puts "Artist: " + artist.id.to_s
      if artist
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
            ext = File.extname(file.original_filename)
            if ext == ''
             ext = Mimes.ext(file.content_type)
            end
            video = artist.videos.create(
                    title: nonil(ApplicationHelper.demotify(video[:title]), 'Untitled'),
                    description: ApplicationHelper.demotify(video[:description]),
                    mime: file.content_type,
                    file: ext,
                    audio_only: file.content_type.include?('audio/'),
                    upvotes: 0, downvotes: 0)
            if params[:video][:genres_string]
              Genre.loadGenres(params[:video][:genres_string], video)
            end
            video.save
            video.setFile(file)
            video.setThumbnail(cover)
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
      else
        error(params[:async], "Error", "An artist could not be found.")
        return
      end
    end
    error(params[:async], "Access Denied", "You can't do that right now.")
  end
  
  def update
    if user_signed_in? && video = Video.where(id: params[:id]).first
      if video.artist.id == current_user.artist_id || current_user.is_admin
        value = ApplicationHelper.demotify(params[:value])
        if params[:field] == 'description'
          video.description = value
          video.save
        elsif params[:field] == 'title'
          video.title = nonil(value, 'Untitled')
          video.save
        elsif params[:field] == 'tags'
          Genre.loadGenres(params[:value], video)
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
      if video.artist.id == current_user.artist_id || current_user.is_admin
        @video = video
	@artist = video.artist
      end
    end
  end
  
  def updateCover
    if user_signed_in? && video = Video.where(id: params[:video][:id]).first
      if video.artist.id == current_user.artist_id || current_user.is_admin
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
    @video = Video.find(params[:id].split(/-/)[0])
    file = Rails.root.join("public", "stream", @video.id.to_s + @video.file).to_s
    response.headers['Content-Length'] = File.size(file).to_s
    send_file(file,
        :filename => "#{@video.id}_#{@video.title}_by_#{@video.artist.name}#{@video.file}",
        :type => @video.mime
    )
  end
  
  def list
    @page = params[:page].to_i
    @results = Pagination.paginate(Video.where(hidden: false).order(:created_at), @page, 50, true)
    render template: '/view/listing', locals: {type_id: 0, type: 'videos', type_label: 'Song', items: @results}
  end
  
  def page
    @page = params[:page].to_i
    @artist = params[:artist]
    if @artist.nil?
      @results = Pagination.paginate(Video.where(hidden: false).order(:created_at), @page, 50, true)
    else
      @results = Pagination.paginate(Artist.find(@artist.to_i).videos.order(:created_at), @page, 8, true)
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
