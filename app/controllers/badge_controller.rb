class BadgeController < ApplicationController
  def index
    if user_signed_in? && current_user.is_staff?
      @allow_modifications = false
    end
    @badges = Badge.all
  end
end
