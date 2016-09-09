class GenreController < ApplicationController
  def view
    if @tag = Tag.where("short_name = ? OR name = ?", params[:name].downcase, params[:name].downcase).first
      if @tag.alias_id
        flash[:notice] = "The tag '" + @tag.name + "' has been aliased to '" + @tag.alias.name + "'"
        if !user_signed_in? || !current_user.is_admin
          return redirect_to action: "view", name: @tag.alias.short_name
        end
      end
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
      @aliases = @tag.aliases
    end
  end
  
  def update
    if user_signed_in? && current_user.is_admin
      if @tag = Tag.where(id: params[:id]).first
        @tag.description = params[:tag][:description]
        if params[:tag][:alias_tag] && (@alias = Tag.where('name = ? OR id = ?', params[:tag][:alias_tag], params[:tag][:alias_tag]).first)
          @tag.set_alias(@alias)
        else
          @tag.alias_id = nil
        end
        @tag.set_name(params[:tag][:suffex])
        implications = Tag.split_tag_string(params[:tag][:tag_string])
        implications = Tag.get_tag_ids(implications)
        implications = Tag.expand_implications(implications)
        if @tag.tag_type
          implications = implications | @tag.tag_type.tag_type_implications.pluck(:implied_id).uniq
        end
        TagImplication.where(tag_id: @tag.id).destroy_all
        implications = implications.uniq.map do |i|
          {tag_id: @tag.id, implied_id: i}
        end
        TagImplication.create(implications)
        return redirect_to action: "tag", controller: "admin"
      end
    end
    render 'layouts/error', locals: { title: 'Access Denied', description: "You can't do that right now." }
  end
  
  def list
    @page = params[:page].to_i
    @results = Pagination.paginate(Tag.includes(:videos, :tag_type).where('alias_id IS NULL').order(:name), @page, 100, false)
    render template: '/view/listing', locals: {type_id: 3, type: 'genres', type_label: 'Tag', items: @results}
  end
  
  def page
    @page = params[:page].to_i
    @results = Pagination.paginate(Tag.includes(:videos, :tag_type).where('alias_id IS NULL').order(:name), @page, 100, false)
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
  
  def hide
    if user_signed_in?
      if (!subscription = TagSubscription.where(user_id: current_user.id, tag_id: params[:id]).first)
        subscription = TagSubscription.create(user_id: current_user.id, tag_id: params[:id], hide: false, spoiler: false, watch: false)
      end
      return render json: {
        hide: subscription.toggle_hidden,
        spoiler: subscription.spoiler,
        watch: subscription.watch
      }
    end
    render status: 401, nothing: true
  end
  
  def spoiler
    if user_signed_in?
      if (!subscription = TagSubscription.where(user_id: current_user.id, tag_id: params[:id]).first)
        subscription = TagSubscription.create(user_id: current_user.id, tag_id: params[:id], hide: false, spoiler: false, watch: false)
      end
      return render json: {
        spoiler: subscription.toggle_spoilered,
        hide: subscription.hide,
        watch: subscription.watch
      }
    end
    render status: 401, nothing: true
  end
  
  def watch
    if user_signed_in?
      if (!subscription = TagSubscription.where(user_id: current_user.id, tag_id: params[:id]).first)
        subscription = TagSubscription.create(user_id: current_user.id, tag_id: params[:id], hide: false, spoiler: false, watch: false)
      end
      return render json: {
        watch: subscription.toggle_watched,
        hide: subscription.hide,
        spoiler: subscription.spoiler
      }
    end
    render status: 401, nothing: true
  end
end
