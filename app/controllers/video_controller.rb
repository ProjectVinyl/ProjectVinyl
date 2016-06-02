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
        video = params[:video]
        video = artist.videos.create(title: video[:title], description: video[:description], upvotes: 0, downvotes: 0)
        song(video, params[:video][:file])
        cover(video, params[:video][:cover])
        video.save
        redirect_to action: "view", id: video.id
        return
      end
    end
    render 'layouts/error', locals: { title: 'Access Denied', description: "You can't do that right now." }
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
  
  def song(video, uploaded_io)
    path = Rails.root.join('public', 'stream', video.id + (video.audio_only ? '.mp3' : '.mp4'))
    File.open(path) do |file|
      file.write(uploaded_io.read)
      video.mime = uploaded_io.content_type
      Ffmpeg.produceWebM(path.to_s)
    end
  end
  
  def cover(video, uploaded_io)
    File.open(Rails.root.join('public', 'cover', video.id)) do |file|
      file.write(uploaded_io.read)
    end
  end
end
