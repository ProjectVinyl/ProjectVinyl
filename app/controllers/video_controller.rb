class VideoController < ApplicationController
  def view
    if @video = Video.where(id: params[:id].split(/-/)[0]).first
      if @video.hidden && (!user_signed_in? || @video.artist_id != current_user.artist_id)
        render 'layouts/error', locals: { title: 'Content Removed', description: "The video you are trying to access is currently not available." }
        return
      end
      @artist = @video.artist
      @queue = @artist.videos.where(hidden: false).where.not(id: @video.id).limit(5).order("RAND()")
      @modificationsAllowed = user_signed_in? && current_user.artist_id == @artist.id
    end
  end
  
  def upload
    if user_signed_in?
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
        puts "File: " + (file ? file.content_type : "nil")
        puts "Cover: " + (cover ? cover.content_type : "nil")
        if file && (file.content_type.include?('video/') || file.content_type.include?('audio/'))
          if file.content_type.include?('video/') || (cover && cover.content_type.include?('image/'))
            video = params[:video]
            video = artist.videos.create(title: nonil(ApplicationHelper.demotify(video[:title]), 'Untitled'), description: ApplicationHelper.demotify(video[:description]), upvotes: 0, downvotes: 0, hidden: false)
            video.audio_only = file.content_type.include?('audio/')
            if params[:genres_string]
              Genre.loadGenres(params[:genres_string], video.video_genres)
            end
            store(video, file, cover)
            video.save
            if params[:async]
              render json: { result: "success", ref: "/view/" + video.id.to_s }
            else
              redirect_to action: "view", id: video.id
            end
            return
          else
            if params[:async]
              render plain: "Cover art is required for audio files.", status: 401
            else
              render 'layouts/error', locals: { title: 'Error', description: "Cover art is required for audio files." }
            end
            return
          end
        end
      else
        if params[:async]
          render plain: "An artist could not be found.", status: 401
        else
          render 'layouts/error', locals: { title: 'Error', description: "An artist could not be found." }
        end
        return
      end
    end
    if params[:async]
      render plain: "Access Denied", status: 401
    else
      render 'layouts/error', locals: { title: 'Access Denied', description: "You can't do that right now." }
    end
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
          Genre.loadGenres(params[:value], video.video_genres)
          video.save
        end
        render status: 200, nothing: true
        return
      end
    end
    render status: 401, nothing: true
  end
  
  def download
    @video = Video.find(params[:id].split(/-/)[0])
    file = Rails.root.join("public", "stream", @video.id.to_s + "." + (@video.audio_only ? 'mp3' : 'mp4')).to_s
    mime = @video.mime
    if !mime
      mime = @video.audio_only ? 'audio/mpeg' : 'video/mp4'
    end
    response.headers['Content-Length'] = File.size(file).to_s
    send_file(file,
        :filename => "#{@video.id}_#{@video.title}_by_#{@video.artist.name}.#{(@video.audio_only ? 'mp3' : 'mp4')}",
        :type => mime
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
  
  def store(video, media, cover)
    video_path = Rails.root.join('public', 'stream', video.id.to_s + (video.audio_only ? '.mp3' : '.mp4'))
    File.open(video_path, 'wb') do |file|
      file.write(media.read)
      file.flush()
    end
    cover_path = Rails.root.join('public', 'cover', video.id.to_s)
    if cover && cover.content_type.include?('image/')
      File.open(cover_path, 'wb') do |file|
        file.write(cover.read)
        file.flush()
      end
    else
      Ffmpeg.extractThumbnail(video_path, cover_path)
    end
    if !video.audio_only
      id = video.id
      Thread.new do
        begin
          Ffmpeg.produceWebM(video_path.to_s)
          video.mime = media.content_type
          video.save
          ActiveRecord::Base.connection.close
        rescue Exception => e
          puts e
        end
      end
    else
      video.mime = media.content_type
      video.save
      ActiveRecord::Base.connection.close
    end
  end
end
