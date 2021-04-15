class FiltersController < ApplicationController

  def show
    if !(@filter = SiteFilter.where(id: params[:id]).first)
      return render_error(
        title: 'Nothing to see here!',
        description: "There was probably a filter here, but we can't find it right now."
      )
    end

    flash[:notice] = 'This is your current filter' if @filter.id == current_filter.id
    @crumb = {
      stack: [
        title: 'Site Filters', link: filters_path
      ],
      title: @filter.name
    }
  end

  def new
    return render_access_denied if !user_signed_in?

    @new_filter = SiteFilter.new(params.permit(:name, :hide_filter, :spoiler_filter, :preferred))

    if params[:copy] && (copy = SiteFilter.where(id: params[:copy].to_i).first)
      @new_filter = copy.dup
      @new_filter.name = "#{current_user.username}'s #{copy.name}"
    end

    @crumb = {
      stack: [
        title: 'Site Filters', link: filters_path
      ],
      title: 'New'
    }
  end

  def create
    return render_access_denied if !user_signed_in?

    @new_filter = __read_update_params

    if !@new_filter[:name] || @new_filter[:name].blank?
      flash[:error] = "You must provide a name"
      return redirect_to action: :new, params: @new_filter
    end

    @global = false
    @new_filter = SiteFilter.create(@new_filter)
    SiteFilter.where.not(id: @new_filter.id).update_all(preferred: false) if @new_filter.preferred

    redirect_to action: :index
  end

  def edit
    return render_access_denied if !user_signed_in?
    return head :not_found if !(@filter = SiteFilter.where(id: params[:id]).first)

    @global = @filter.user.nil?
  end

  def update
    return render_access_denied if !user_signed_in?
    return head :not_found if !(@filter = SiteFilter.where(id: params[:id]).first)

    @filter.update(__read_update_params)
    SiteFilter.where.not(id: @filter.id).update_all(preferred: false) if @filter.preferred

    redirect_to action: :index
  end

  def __read_update_params
    filter = params[:filter].permit(:name, :description, :spoiler_tags, :hide_tags, :hide_filter, :spoiler_filter, :preferred)
    filter = filter.except(:preferred) if !current_user.is_staff?

    if current_user.is_staff?
      @global = (params[:filter][:global] && params[:filter][:global] == '1')
      filter[:preferred] = false if !@global
      filter[:user_id] = @global ? nil : current_user.id
    end
    filter
  end

  def destroy
    return render_access_denied if !user_signed_in?
    return head :not_found if !(@filter = SiteFilter.where(id: params[:id]).first)

    redirect_to action: :index

    return fail_fast('Filter cannot be deleted. It is the default site filter.') if @filter.preferred
    return fail_fast('You cannot do that right now.') if !current_user.is_staff? && @filter.user_id != current_user.id

    flash[:message] = 'The filter has been deleted'
    if current_user.site_filter_id == @filter.id
      current_user.site_filter = default_filter
      current_user.save
      flash[:message] = "Your filter has been changed to #{default_filter.name} because the one you had selected has been deleted"
    end
    User.where(site_filter_id: @filter.id).update_all(site_filter_id: default_filter.id)

    @filter.destroy
  end

  def index
    @global_filters = Pagination.paginate(SiteFilter.where(user_id: nil), 0, 10, false)
    @user_filters = Pagination.paginate(current_user.site_filters, 0, 10, false) if user_signed_in?
    @crumb = {
      stack: [ ],
      title: 'Site Filters'
    }
  end

  private
  def fail_fast(msg)
    flash[:message] = msg
  end
end
