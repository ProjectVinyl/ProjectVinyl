class Report < ApplicationRecord
  belongs_to :direct_user, class_name: "User", foreign_key: "user_id"
  belongs_to :video

  has_one :comment_thread, as: :owner, dependent: :destroy

  def user
    self.direct_user || @dummy || (@dummy = User.dummy(self.user_id))
  end

  def user=(user)
    self.direct_user = user
  end

  def write(msg)
    self.other << "<br>#{msg}"
  end
  
  def bump(sender, state)
    if state.nil?
      return
    end
    
    @changed = nil
    
    if state == 'open'
      if !self.resolved.nil?
        self.resolved = nil
        @changed = 'reopened'
      end
    elsif state == 'close'
      if self.resolved != false
        self.resolved = false
        @changed = 'closed'
      end
    elsif state == 'resolve'
      if !self.resolved
        self.resolved = true
        @changed = 'resolved'
      end
    end
    
    if @changed.nil?
      return
    end
    
    Notification.notify_admins(self,
      "Report <b>#{sender.title}</b> has been #{changed}", sender.location)
    self.save
  end
end
