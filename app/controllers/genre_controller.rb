class GenreController < ApplicationController
  def view
puts params[:name]
    if @tag = Tag.where("lower(name) = ?", params[:name].downcase).first
      @totalVideos = @tag.videos.length
      @totalArtists = @tag.artists.length
      @videos = @tag.videos.where(hidden: false).order(:created_at).reverse_order.limit(16)
      @artists = @tag.artists.order(:updated_at).reverse_order.limit(16)
    end
  end
  
  def list
    @page = params[:page].to_i
    @results = Pagination.paginate(Tag.includes(:videos, :tag_type).order(:name), @page, 100, false)
    render template: '/view/listing', locals: {type_id: 3, type: 'genres', type_label: 'Tag', items: @results}
  end
  
  def page
    @page = params[:page].to_i
    @results = Pagination.paginate(Tag.includes(:videos, :tag_type).order(:name), @page, 100, false)
    render json: {
      content: render_to_string(partial: '/layouts/genre_thumb_h.html.erb', collection: @results.records),
      pages: @results.pages,
      page: @results.page
    }
  end
  
  def find
    render json: {
      results: Tag.find_matching_tags(params[:q])
    }
  end
end
