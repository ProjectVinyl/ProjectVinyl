module Forums
  class BadgesController < ApplicationController
    def index
      @path_type = 'forums'
      @badges = Badge.where(hidden: false)
    end
  end
end