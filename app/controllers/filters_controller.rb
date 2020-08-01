class FiltersController < ApplicationController

  def show
    if !(@filter = SiteFilter.where(id: params[:id]).first)
      return render_error(
        title: 'Nothing to see here!',
        description: "There was probably a filter here, but we can't find it right now."
      )
    end
  end

  def new
    return render_access_denied if !user_signed_in?

    @new_filter = SiteFilter.new(params.permit(:name, :hide_filter, :spoiler_filter, :preferred))
    @new_filter.user = current_user

    if params[:copy] && (copy = SiteFilter.where(id: params[:copy].to_i).first)
      @new_filter.name = "#{current_user.username}'s #{copy.name}"
      @new_filter.hide_filter = copy.hide_filter
      @new_filter.spoiler_filter = copy.spoiler_filter
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

    @new_filter = params[:filter].permit(:name, :hide_filter, :spoiler_filter, :preferred)
    @new_filter[:user_id] = current_user.id if !current_user.is_staff? || (params[:global] && params[:global][:set] == '1')
    @new_filter = @new_filter.except(:preferred) if !current_user.is_staff?
    
    if !@new_filter[:name] || @new_filter[:name].blank?
      flash[:error] = "Name is required"
      return redirect_to action: :new, params: @new_filter
    end

    @new_filter = SiteFilter.create(@new_filter)

    redirect_to action: :index
  end

  def edit
    return render_access_denied if !user_signed_in?
  end

  def update
    return render_access_denied if !user_signed_in?
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
