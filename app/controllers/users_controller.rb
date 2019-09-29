class UsersController < Users::BaseUsersController

  def index
    render_listing_total User.all.order(:created_at), params[:page].to_i, 50, true, {
      table: 'users', label: 'User'
    }
  end

  def show
    check_details_then do |user, edits_allowed|
      @tags = @user.tags.includes(:tag_type)
      @modifications_allowed = edits_allowed

      if @user.tag_id
        @art = Pagination.paginate(@user.tag.videos.listable.with_likes(current_user), 0, 8, true)
      end

      @videos = edits_allowed ? @user.videos.includes(:tags).where(duplicate_id: 0) : @user.videos.listable
      @videos = Pagination.paginate(@videos.order(:created_at).with_likes(current_user), 0, 8, true)

      @albums = edits_allowed ? @user.albums : @user.albums.where(hidden: false, listing: 0)
      @albums = Pagination.paginate(@albums.order(:created_at), 0, 8, true)
      @comments = Pagination.paginate(@user.comments.visible.decorated.with_likes(current_user).order(:created_at), 0, 3, true)
    end
  end

  def update
    check_then do |user|
      input = params[:user]

      if current_user.is_contributor?
        user.tag = Tag.by_name_or_id(input[:tag]).first
      end
      user.set_name(input[:username])
      user.description = input[:description]
      user.bio = input[:bio]
      user.set_tags(input[:tag_string])
      user.save

      if current_user.is_staff? && params[:user_id]
        return redirect_to action: "view", id: user.id
      end

      redirect_to action: :edit, controller: "users/registrations"
    end
  end
end