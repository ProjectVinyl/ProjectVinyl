class ArtistController < ApplicationController
  def view
    if @artist = Artist.where(id: params[:id].split(/-/)[0]).first
      @videos = Pagination.paginate(@artist.videos, 0, 8, true)
      @albums = Pagination.paginate(@artist.albums, 0, 8, true)
    end
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
  
  def avatar
    uploaded_io = params[:author][:avatar]
    File.open(Rails.root.join('public', 'avatar', params[:author][:id])) do |file|
      file.write(uploaded_io.read)
      @artist = Artist.find(params[:artist][:id])
      @artist.mime = uploaded_io.content_type
      @artist.save
    end
  end
end
