class BadgeController < ApplicationController
  def index
    @badges = Badge.all #where(hidden: false)
  end
end
