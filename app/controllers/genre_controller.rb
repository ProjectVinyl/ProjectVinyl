class GenreController < ApplicationController
  def view
    if @tag = Tag.where("short_name = ? OR name = ?", params[:name].downcase, params[:name].downcase).first
      @modificationsAllowed = user_signed_in? && current_user.is_admin
      @totalVideos = @tag.videos.length
      @totalUsers = @tag.users.length
      @videos = @tag.videos.where(hidden: false).order(:created_at).reverse_order.limit(16)
      @users = @tag.users.order(:updated_at).reverse_order.limit(16)
      if @tag.tag_type_id == 1
        @user = User.where(tag_id: @tag.id).first
      end
      @implies = @tag.implications
      @implied = @tag.implicators
    end
  end
  
  def list
    @page = params[:page].to_i
    @results = Pagination.paginate(Tag.includes(:videos, :tag_type).where('tag_type_id > 0 OR video_count > 0 OR user_count > 0').order(:name), @page, 100, false)
    render template: '/view/listing', locals: {type_id: 3, type: 'genres', type_label: 'Tag', items: @results}
  end
  
  def page
    @page = params[:page].to_i
    @results = Pagination.paginate(Tag.includes(:videos, :tag_type).where('tag_type_id > 0 OR video_count > 0 OR user_count > 0').order(:name), @page, 100, false)
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
