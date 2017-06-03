class GenreController < ApplicationController
  def view
    name = params[:name].downcase
    if @tag = Tag.where("short_name = ? OR name = ? OR id = ?", name, name, name).first
      if @tag.alias_id
        flash[:notice] = "The tag '" + @tag.name + "' has been aliased to '" + @tag.alias.name + "'"
        if !user_signed_in? || !current_user.is_staff?
          return redirect_to action: "view", name: @tag.alias.short_name
        end
      end
      @modificationsAllowed = user_signed_in? && current_user.is_contributor?
      @totalVideos = @tag.videos.length
      @totalUsers = @tag.users.length
      @videos = @tag.videos.where(hidden: false).order(:created_at)
      @videos = Pagination.paginate(@videos, 0, 8, true)
      @users = @tag.users.order(:updated_at)
      @users = Pagination.paginate(@users, 0, 8, true)
      if @tag.tag_type_id == 1
        @user = User.where(tag_id: @tag.id).first
      end
      @implies = @tag.implications
      @implied = @tag.implicators
      @aliases = @tag.aliases
    end
  end
  
  def update
    if user_signed_in? && current_user.is_staff?
      if @tag = Tag.where(id: params[:id]).first
        @tag.description = params[:tag][:description]
        if params[:tag][:alias_tag] && (@alias = Tag.by_name_or_id(params[:tag][:alias_tag])).first
          @tag.set_alias(@alias)
        else
          @tag.unset_alias
        end
        @tag.tag_type = TagType.where(id: params[:tag][:tag_type_id]).first
        if !@tag.set_name(params[:tag][:suffex])
          flash[:alert] = "Duplicate Error: A Tag named '" + params[:tag][:suffex] + "' already exists"
          @tag.save
        end
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
  
  def videos
    if @tag = Tag.where(id: params[:id]).first
      @results = Pagination.paginate(@tag.videos.where(hidden: false).includes(:tags).order(:created_at), params[:page].to_i, 8, true)
      render json: {
        content: render_to_string(partial: '/layouts/video_thumb_h.html.erb', collection: @results.records),
        pages: @results.pages,
        page: @results.page
      }
    else
      render status: 404, nothing: true
    end
  end
  
  def users
    if @tag = Tag.where(id: params[:id]).first
      @results = Pagination.paginate(@tag.users.order(:updated_at_at), params[:page].to_i, 8, true)
      render json: {
        content: render_to_string(partial: '/layouts/artist_thumb_h.html.erb', collection: @results.records),
        pages: @results.pages,
        page: @results.page
      }
    else
      render status: 404, nothing: true
    end
  end
  
  def find
    render json: {
      results: Tag.find_matching_tags(params[:q])
    }
  end
  
  def hide
    if user_signed_in?
      if params[:id].to_i.to_s != params[:id]
        params[:id] = Tag.where(name: params[:id]).first.id
      end
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
      if params[:id].to_i.to_s != params[:id]
        params[:id] = Tag.where(name: params[:id]).first.id
      end
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
      if params[:id].to_i.to_s != params[:id]
        params[:id] = Tag.where(name: params[:id]).first.id
      end
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
