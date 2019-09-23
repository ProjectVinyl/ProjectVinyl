module Forum
  class BadgesController < ApplicationController
    def index
      @badges = Badge.where(hidden: false)
    end
  end
end