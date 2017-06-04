class BadgeController < ApplicationController
  def index
    if user_signed_in? && current_user.is_staff?
      @allowModifications = false
      @badges = Badge.all
      return
    end
    @badges = Badge.all
  end
end
