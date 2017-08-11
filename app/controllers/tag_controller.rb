class TagController < ApplicationController
  def view
    name = params[:name].downcase
    if !(@tag = Tag.where("short_name = ? OR name = ? OR id = ?", name, name, name).first)
      return render_error(
        title: 'Nothing to see here but us Fish!',
        description: 'This This tag does not exist.'
      )
    end
    
    if @tag.alias_id
      flash[:notice] = "The tag '" + @tag.name + "' has been aliased to '" + @tag.alias.name + "'"
      if !user_signed_in? || !current_user.is_staff?
        return redirect_to action: "view", name: @tag.alias.short_name
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
    @page = params[:page].to_i
    @results = Tag.includes(:videos, :tag_type).where('alias_id IS NULL').order(:name)
    render_listing @results, @page, 100, false, {
      id: 3, table: 'tags', label: 'Tag'
    }
  end
  
  def page
    @records = Tag.includes(:videos, :tag_type).where('alias_id IS NULL').order(:name)
    render_pagination 'tag/thumb_h', @records, params[:page].to_i, 100, false
  end
  
  def videos
    if !(@tag = Tag.where(id: params[:id]).first)
      return head 404
    end
    @records = @tag.videos.where(hidden: false).includes(:tags).order(:created_at)
    render_pagination 'video/thumb_h', @records, params[:page].to_i, 8, true
  end
  
  def users
    if !(@tag = Tag.where(id: params[:id]).first)
      return head 404
    end
    @records = @tag.users.order(:updated_at_at)
    render_pagination 'user/thumb_h', @records, params[:page].to_i, 8, true
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
    
    if params[:id].to_i.to_s != params[:id]
      params[:id] = Tag.where(name: params[:id]).first.id
    end
    if !(subscription = TagSubscription.where(user_id: current_user.id, tag_id: params[:id]).first)
      subscription = TagSubscription.new(
        user_id: current_user.id,
        tag_id: params[:id],
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
