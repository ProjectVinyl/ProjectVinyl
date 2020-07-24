class TagsController < ApplicationController
  include Searchable

  configure_ordering [:name]
  
  def show
    name = params[:id].downcase
    if !(@tag = Tag.by_name_or_id(name).first)
      return render_error(
        title: 'Nothing to see here but us Fish!',
        description: 'This tag does not exist.'
      )
    end

    if @tag.alias_id
      flash[:notice] = "The tag '#{@tag.name}' has been aliased to '#{@tag.alias.name}'"
      if !user_signed_in? || !current_user.is_staff?
        return redirect_to action: :view, name: @tag.alias.short_name
      end
    end

    @modifications_allowed = user_signed_in? && current_user.is_contributor?

    @total_videos = @tag.videos.length
    @total_users = @tag.users.length

    @videos = Pagination.paginate(@tag.videos.where(hidden: false).order(:created_at), 0, 8, true)
    @users = Pagination.paginate(@tag.users.order(:updated_at), 0, 8, true)

    @user = User.where(tag_id: @tag.id).first if @tag.tag_type_id == 1

    @implies = @tag.implications
    @implied = @tag.implicators
    @aliases = @tag.aliases
  end

  def index
    read_search_params params
    
    if filtered?
      @records = Tag.includes(:videos, :tag_type).where('LOWER(name) LIKE ?', @query.downcase.gsub(/\*/, '%'))
    else
      @records = Tag.includes(:videos, :tag_type).where('alias_id IS NULL')
    end

    render_listing_total @records.order(order_field), @page, 100, !@ascending, {
      template: 'pagination/search', table: 'tags', label: 'Tag'
    }
  end
end
