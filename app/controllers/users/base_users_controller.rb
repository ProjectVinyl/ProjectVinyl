module Users
  class BaseUsersController < ApplicationController
    protected
    def check_details_then
      if !(@user = User.where(id: params[:user_id] || params[:id]).first)
        return render_error(
          title: 'Nothing to see here!',
          description: 'If there was someone here they\'re probably gone now. ... sorry.'
        )
      end

      yield(@user, user_signed_in? && (current_user.id == @user.id || current_user.is_staff?))
    end

    def check_then
      return render_access_denied if !user_signed_in?

      id = (params[:user_id] || params[:id]).to_i

      return yield(current_user) if id == current_user.id
      return render_access_denied if !current_user.is_staff?
      return head :not_found if !(user = User.where(id: id).first)
      yield(user)
    end

    def load_art_module
      return if @art
      return if !@user.tag_id
      @art = current_filter.videos.where(hidden: false, duplicate_id: 0, tags: [ @user.tag.name ])
      @art = @art.order(:created_at).reverse_order.paginate(0, 9){|t| t.for_thumbnails(current_user) }
    end

    def load_favourites_module
      return if @favourites
      @favourites = current_filter.videos.where(hidden: false, duplicate_id: 0, albums: [ @user.stars.id ])
      @favourites = @favourites.where(listing: 0) if !@modifications_allowed
      @favourites = @favourites.order(:updated_at, :created_at).reverse_order.paginate(0, 9){|t| t.for_thumbnails(current_user)}
    end

    def load_recently_watched_module
      return if @watched
      @watched = @user.watched_videos.unmerged.reverse_order
      @watched = @watched.listable if !@modifications_allowed

      @watched_count = @watched.count(:all)

      watched_ids = @watched.limit(9).map(&:id)
      @watched = current_filter.videos.where(id: watched_ids).fixed_order(watched_ids)
      @watched = @watched.paginate(0, 9) {|t| t.for_thumbnails(current_user)}
    end

    def load_uploads_module
      return if @videos
      @videos = current_filter.videos.where(hidden: false, duplicate_id: 0, user_id: @user.id)
      @videos = @videos.where(listing: 0) if !@modifications_allowed
      @videos = @videos.order(:created_at).reverse_order.paginate(0, 9) {|t| t.for_thumbnails(current_user) }
    end

    def load_albums_module
      return if @albums
      @albums = @user.albums.where(hidden: false)
      @albums = @albums.where(listing: 0) if !@modifications_allowed
      @albums = Pagination.paginate(@albums.order(:created_at), 0, 9, true)
    end

    def load_comments_module
      return if @comments
      @comments = @user.comments.visible.decorated.with_owner.with_likes(current_user).order(:created_at)
      @comments = @comments.where(anonymous_id: 0) if !@modifications_allowed
      @comments = Pagination.paginate(@comments, 0, 4, true)
    end

    def load_profile_module(type)
      puts "Loading profile data for #{type}"
      sym = "load_#{type}_module".to_sym
      #puts " Error cannot load #{sym}" if !respond_to?(sym)
      send(sym) if self.class.method_defined?(sym)
    end
  end
end
