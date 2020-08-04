module Filters
  class CurrentFiltersController < ApplicationController
    skip_before_action :verify_authenticity_token

    def update
      if user_signed_in?
        if (@filter = SiteFilter.where(id: params[:filter_id]).where('user_id IS NULL OR user_id = ?', current_user.id).first)
          current_user.site_filter = @filter
          current_user.save
        end
      else
        if (@filter = SiteFilter.where(id: params[:filter_id]).where(user_id: nil).first)
          cookies[:filter] = {
            value: @filter.id, expires: Time.now + 1.hour
          }
        end
      end

      bounce_back
    end
  end
end
