class TagController < ApplicationController
  def view
    name = params[:name].downcase
    if !(@tag = Tag.where("short_name = ? OR name = ? OR id = ?", name, name, name).first)
      return render 'layouts/error', locals: { title: 'Nothing to see here but us Fish!', description: 'This This tag does not exist.' }
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
    @results = Pagination.paginate(Tag.includes(:videos, :tag_type).where('alias_id IS NULL').order(:name), @page, 100, false)
    render template: 'pagination/listing', locals: { type_id: 3, type: 'tags', type_label: 'Tag', items: @results }
  end

  def page
    @page = params[:page].to_i
    @results = Pagination.paginate(Tag.includes(:videos, :tag_type).where('alias_id IS NULL').order(:name), @page, 100, false)
    render json: {
      content: render_to_string(partial: 'tag/thumb_h.html.erb', collection: @results.records),
      pages: @results.pages,
      page: @results.page
    }
  end

  def videos
    if @tag = Tag.where(id: params[:id]).first
      @results = Pagination.paginate(@tag.videos.where(hidden: false).includes(:tags).order(:created_at), params[:page].to_i, 8, true)
      return render json: {
        content: render_to_string(partial: 'video/thumb_h.html.erb', collection: @results.records),
        pages: @results.pages,
        page: @results.page
      }
    end
    head 404
  end

  def users
    if @tag = Tag.where(id: params[:id]).first
      @results = Pagination.paginate(@tag.users.order(:updated_at_at), params[:page].to_i, 8, true)
      return render json: {
        content: render_to_string(partial: 'user/thumb_h.html.erb', collection: @results.records),
        pages: @results.pages,
        page: @results.page
      }
    end
    head 404
  end
  
  def hide
    if user_signed_in?
      if params[:id].to_i.to_s != params[:id]
        params[:id] = Tag.where(name: params[:id]).first.id
      end
      if !subscription = TagSubscription.where(user_id: current_user.id, tag_id: params[:id]).first
        subscription = TagSubscription.create(user_id: current_user.id, tag_id: params[:id], hide: false, spoiler: false, watch: false)
      end
      return render json: {
        hide: subscription.toggle_hidden,
        spoiler: subscription.spoiler,
        watch: subscription.watch
      }
    end
    head 401
  end

  def spoiler
    if user_signed_in?
      if params[:id].to_i.to_s != params[:id]
        params[:id] = Tag.where(name: params[:id]).first.id
      end
      if !subscription = TagSubscription.where(user_id: current_user.id, tag_id: params[:id]).first
        subscription = TagSubscription.create(user_id: current_user.id, tag_id: params[:id], hide: false, spoiler: false, watch: false)
      end
      return render json: {
        spoiler: subscription.toggle_spoilered,
        hide: subscription.hide,
        watch: subscription.watch
      }
    end
    head 401
  end

  def watch
    if user_signed_in?
      if params[:id].to_i.to_s != params[:id]
        params[:id] = Tag.where(name: params[:id]).first.id
      end
      if !subscription = TagSubscription.where(user_id: current_user.id, tag_id: params[:id]).first
        subscription = TagSubscription.create(user_id: current_user.id, tag_id: params[:id], hide: false, spoiler: false, watch: false)
      end
      return render json: {
        watch: subscription.toggle_watched,
        hide: subscription.hide,
        spoiler: subscription.spoiler
      }
    end
    head 401
  end
end
