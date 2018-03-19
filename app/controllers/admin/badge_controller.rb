class BadgeController < ApplicationController
  before_action :authenticate_user!
  
  def index
    if !current_user.is_staff?
      return render_access_denied
    end
    
    @badges = Badge.all
    @crumb = {
      stack: [
        { link: '/admin', title: 'Admin' }
      ],
      title: "Badges"
    }
end
