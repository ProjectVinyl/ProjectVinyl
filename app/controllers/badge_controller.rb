class BadgeController < ApplicationController
  def index
    @badges = Badge.where(hidden: false)
  end
end
