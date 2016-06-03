class VideoController < ApplicationController
  def view
    if @video = Video.where(id: params[:id].split(/-/)[0]).first
      @artist = @video.artist
      @queue = @artist.videos.where.not(id: @video.id).limit(5).order("RAND()")
      @modificationsAllowed = user_signed_in? && !current_user.artist_id.nil? && current_user.artist_id == @artist.id
    end
  end
  
  def upload
    if user_signed_in?
      if @artist = Artist.where(id: current_user.artist_id).first
        @video = Video.new
        return
      end
    end
    render 'layouts/error', locals: { title: 'Access Denied', description: "You can't do that right now." }
  end
  
  def create
    if user_signed_in?
      if artist = Artist.where(id: current_user.artist_id).first
        file = params[:video][:file]
        cover = params[:video][:cover]
        if file && (file.content_type.include?('video/') || file.content_type.include?('audio/'))
          if (cover && cover.content_type.include?('image/')) || file.content_type.include?('video/')
            video = params[:video]
            video = artist.videos.create(title: ApplicationHelper.demotify(video[:title]), description: ApplicationHelper.demotify(video[:description]), upvotes: 0, downvotes: 0)
            store(video, file, cover)
            video.save
            redirect_to action: "view", id: video.id
            return
          end
        end
      end
    end
    render 'layouts/error', locals: { title: 'Access Denied', description: "You can't do that right now." }
  end
  
  def update
    if video = Video.where(id: params[:id]).first
      value = ApplicationHelper.demotify(params[:value])
      if params[:field] == 'description'
        video.description = value
        video.save
      elsif params[:field] == 'title'
        video.title = value
        video.save
      end
      render status: 200, nothing: true
      return
    end
    render status: 401, nothing: true
  end
  
  def download
    @video = Video.find(params[:id].split(/-/)[0])
    send_file("#{Rails.root}/public/stream/#{@video.id}.#{(@video.audio_only ? 'mp3' : 'mp4')}",
        :filename => "#{@video.id}_#{@video.title}_by_#{@video.artist.name}.#{(@video.audio_only ? 'mp3' : 'mp4')}",
        :type => @video.mime
    )
  end
  
  def list
    @page = params[:page].to_i
    @results = Pagination.paginate(Video.order(:created_at), @page, 50, true)
    render template: '/view/listing', locals: {type_id: 0, type: 'videos', type_label: 'Song', items: @results}
  end
  
  def page
    @page = params[:page].to_i
    @artist = params[:artist]
    if @artist.nil?
      @results = Pagination.paginate(Video.order(:created_at), @page, 50, true)
    else
      @results = Pagination.paginate(Artist.find(@artist.to_i).videos.order(:created_at), @page, 8, true)
    end
    render json: {
      content: render_to_string(partial: '/layouts/video_thumb_h.html.erb', collection: @results.records),
      pages: @results.pages,
      page: @results.page
    }
  end
  
  def store(video, cover, file)
    video_path = Rails.root.join('public', 'stream', video.id.to_s + (video.audio_only ? '.mp3' : '.mp4'))
    File.open(path, 'wb') do |file|
      file.write(file.read)
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
    #Don't block, encode to webm in the background and update video state when complete
    if fork.nil?
      Ffmpeg.produceWebM(video_path.to_s)
      video.mime = file.content_type
      video.save
    end
  end
end
