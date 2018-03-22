class TagsController < ApplicationController
  def show
    name = params[:name].downcase
    if !(@tag = Tag.where("short_name = ? OR name = ? OR id = ?", name, name, name).first)
      return render_error(
        title: 'Nothing to see here but us Fish!',
        description: 'This This tag does not exist.'
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
    @records = Tag.includes(:videos, :tag_type).where('alias_id IS NULL').order(:name)
    render_listing_total @records, params[:page].to_i, 100, false, {
      table: 'tags', label: 'Tag'
    }
  end
  
  def videos
    if !(@tag = Tag.where(id: params[:tag_id]).first)
      return head :not_found
    end
    @records = @tag.videos.where(hidden: false).includes(:tags).order(:created_at)
    render_pagination 'videos/thumb_h', @records, params[:page].to_i, 8, true
  end
  
  def users
    if !(@tag = Tag.where(id: params[:tag_id]).first)
      return head :not_found
    end
    @records = @tag.users.order(:updated_at_at)
    render_pagination 'users/thumb_h', @records, params[:page].to_i, 8, true
  end
  
  def aliases
    @aliases = Tag.includes(:alias => [:videos, :users]).where('alias_id > 0').order(:name)
    @aliases = Pagination.paginate(@aliases, params[:page].to_i, 10, true)
    
    if params[:format] == 'json'
      render_pagination_json 'tags/alias', @aliases
    end
  end
  
  def implied
    @implied = Tag.includes(:implications).references(:implications).where('`tag_implications`.id IS NOT NULL').order(:name)
    @implied = Pagination.paginate(@implied, params[:page].to_i, 10, true)
    
    if params[:format] == 'json'
      render_pagination_json 'tags/tag_implication', @implied
    end
  end
  
  def hide
    toggle_action {|subscription| subscription.toggle_hidden }
  end

  def spoiler
    toggle_action {|subscription| subscription.toggle_spoilered }
  end

  def watch
    toggle_action {|subscription| subscription.toggle_watched }
  end
  
  private
  def toggle_action
    if !user_signed_in?
      return head 401
    end
    
    if params[:tag_id].to_i.to_s != params[:tag_id]
      params[:tag_id] = Tag.where(name: params[:tag_id]).first.id
    end
    if !(subscription = TagSubscription.where(user_id: current_user.id, tag_id: params[:tag_id]).first)
      subscription = TagSubscription.new(
        user_id: current_user.id,
        tag_id: params[:tag_id],
        hide: false,
        spoiler: false,
        watch: false
      )
    end
    yield(subscription)
    render json: {
      hide: subscription.hide,
      spoiler: subscription.spoiler,
      watch: subscription.watch
    }
  end
end
