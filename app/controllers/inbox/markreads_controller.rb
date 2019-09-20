module Inbox
  class MarkreadsController < BaseInboxController
    before_action :check_requirements, only: [:update]

    def update
      @pm.unread = !@pm.unread
      @pm.save
      render json: {
        added: @pm.unread,
        tabs: tab_changes
      }
    end
  end
end