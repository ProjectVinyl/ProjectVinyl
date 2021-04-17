class UsersController < Users::BaseUsersController
  include Searchable

  configure_ordering [:username, :created_at], only: [:index]

  def show
    check_details_then do |user, edits_allowed|
      @tags = @user.tags.ordered
      @modifications_allowed = edits_allowed
      @user.profile_modules.pluck(:module_type).uniq.each do |t|
        load_profile_module t
      end
      @profile = { username: @user.username }
    end
  end

  def update
    check_then do |user|
      input = params[:user]

      user.tag = Tag.by_name_or_id(input[:tag]).first if current_user.is_contributor?
      user.username = input[:username]
      user.description = input[:description]
      user.bio = input[:bio]
      user.default_listing = (input[:default_listing] || 0).to_i
      user.tag_string = input[:tag_string] if input[:tag_string]
      user.time_zone = input[:time_zone]
      user.save
      user.update_index

      if (params[:video][:apply_to_all] == '1')
        Video.where(user_id: user).update_all(listing: user.default_listing)
        Video.where(user_id: user).update_index
      end

      return redirect_to action: :edit, controller: "users/registrations" if user.id == current_user.id
      redirect_to action: :show, controller: "admin/users"
    end
  end

  def index
    read_search_params params
    if filtered?
      @records = ProjectVinyl::Search::ActiveRecord.new(User)
        .must(ProjectVinyl::Search.interpret(@query, ProjectVinyl::Search::USER_INDEX_PARAMS, current_user).to_hash)
        .order(order_field)
      @records = @records.reverse_order if !@ascending
      @records = @records.paginate(@page, 50)
    else
      @records = Pagination.paginate(User.all.order(order_field), @page, 50, !@ascending)
    end

    render_paginated @records, {
      template: 'pagination/omni_search', table: 'users', label: 'User'
    }
  end
end