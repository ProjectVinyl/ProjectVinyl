class GenreController < ApplicationController
  def view
    if @genre = Genre.where('name = ?', ApplicationHelper.url_unsafe(params[:name])).first
      @videos = @genre.videos.order(:created_at).reverse_order.limit(16)
    end
  end
end
