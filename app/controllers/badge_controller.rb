class BadgeController < ApplicationController
  def index
    if user_signed_in? && current_user.is_staff?
      @allow_modifications = true
      @badges = Badge.all
    else
      @badges = Badge.all #where(hidden: false)
    end
  end
end
