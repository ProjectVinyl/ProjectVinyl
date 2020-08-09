module FiltersHelper

  def default_filter
    @default_filter ||= SiteFilter.where(user_id: nil, preferred: true).first || SiteFilter.new
  end

  def session_filter
    @session_filter ||= SiteFilter.where(id: cookies[:filter], user_id: nil).first if cookies[:filter]
    @session_filter || default_filter
  end

  def current_filter
    @current_filter ||= user_signed_in? && current_user.site_filter ? current_user.site_filter : session_filter
  end

  def can_modify_filter?
    user_signed_in? && current_filter.user_id == current_user.id
  end
end
