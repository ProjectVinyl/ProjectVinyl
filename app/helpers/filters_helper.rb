module FiltersHelper

  def default_filter
    @default_filter ||= SiteFilter.where(user_id: nil, preferred: true).first || SiteFilter.new
  end

  def current_filter
    @current_filter ||= user_signed_in? && current_user.site_filter ? current_user.site_filter : default_filter
  end
end
