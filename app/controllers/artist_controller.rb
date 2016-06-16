class ArtistController < ApplicationController
  def view
    if @artist = Artist.where(id: params[:id].split(/-/)[0]).first
      @videos = user_signed_in? && current_user.artist_id == @artist.id ? @artist.videos : @artist.videos.where(hidden: false)
      @videos = Pagination.paginate(@videos, 0, 8, true)
      @albums = Pagination.paginate(@artist.albums, 0, 8, true)
      @modificationsAllowed = user_signed_in? && (current_user.artist_id == @artist.id || current_user.is_admin)
    end
  end
  
  def new
    if (!user_signed_in? || current_user.artist_id) && !current_user.is_admin
      redirect_to action: "edit", controller: "devise/registrations"
      return
    end
    @artist = Artist.new
  end
  
  def create
    if user_signed_in? && (!current_user.artist_id || current_user.is_admin)
      artist = params[:artist]
      file = artist[:avatar]
      artist = Artist.create(
                 name: ApplicationHelper.demotify(artist[:name]),
                 description: ApplicationHelper.demotify(artist[:description]),
                 bio: ApplicationHelper.demotify(artist[:bio])
               )
      if params[:artist][:genres_string]
        Genre.loadGenres(params[:artist][:genres_string], artist.artist_genres)
      end
      if file && file.content_type.include?('image/')
        avatar(artist, file)
      end
      artist.save
      if !current_user.artist_id
        current_user.artist_id = artist.id
        current_user.save
      end
      redirect_to action: "view", id: artist.id
      return
    end
    render 'layouts/error', locals: { title: 'Access Denied', description: "You can't do that right now." }
  end
  
  def update
    input = params[:artist]
    if user_signed_in?
      if current_user.is_admin && params[:artist_id]
        artist = Artist.where(id: params[:artist_id]).first
      elsif
        artist = Artist.where(id: current_user.artist_id).first
      end
      if artist
        artist.name = ApplicationHelper.demotify(input[:name])
        artist.description = ApplicationHelper.demotify(input[:description])
        artist.bio = ApplicationHelper.demotify(input[:bio])
        if input[:genres_string]
          Genre.loadGenres(input[:genres_string], artist.artist_genres)
        end
        if file = input[:avatar] && file.content_type.include?('image/')
          avatar(artist, file)
        end
        artist.save
        if current_user.is_admin && params[:artist_id]
          redirect_to action: "view", id: artist.id
        else
          redirect_to action: "edit", controller: "devise/registrations"
        end
        return
      end
    end
    render 'layouts/error', locals: { title: 'Access Denied', description: "You can't do that right now." }
  end
  
  def list
    @page = params[:page].to_i
    @results = Pagination.paginate(Artist.order(:created_at), @page, 50, true)
    render template: '/view/listing', locals: {type_id: 2, type: 'artists', type_label: 'Artist', items: @results}
  end
  
  def page
    @page = params[:page].to_i
    @results = Pagination.paginate(Artist.order(:created_at), @page, 50, true)
    render json: {
      content: render_to_string(partial: '/layouts/artist_thumb_h.html.erb', collection: @results.records),
      pages: @results.pages,
      page: @results.page
    }
  end
  
  private
  def avatar(artist, uploaded_io)
    File.open(Rails.root.join('public', 'avatar', artist.id.to_s), 'wb') do |file|
      file.write(uploaded_io.read)
      artist.mime = uploaded_io.content_type
      artist.save
    end
  end
end
