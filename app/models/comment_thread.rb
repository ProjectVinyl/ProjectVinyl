class CommentThread < ActiveRecord::Base
  belongs_to :direct_user, class_name: "User", foreign_key: "user_id"

  has_many :comments, dependent: :destroy, counter_cache: "total_comments"
  has_many :thread_subscriptions, dependent: :destroy
  has_many :subscribers, through: :thread_subscriptions, class_name: 'User'

  belongs_to :owner, polymorphic: true

  def user
    self.direct_user || @dummy || (@dummy = User.dummy(self.user_id))
  end

  def user=(user)
    self.direct_user = user
  end

  def private_message?
    self.owner_type == 'Pm'
  end

  def contributing?(user)
    !private_message? || (Pm.where('comment_thread_id = ? AND (sender_id = ? OR receiver_id = ?)', self.id, user.id, user.id).count > 0)
  end

  def get_title
    self.title.present? ? self.title : "Untitled"
  end

  def set_title(name)
    name = ApplicationHelper.check_and_trunk(name, self.title)
    self.title = name
    self.safe_title = ApplicationHelper.url_safe(name)
    self.save
  end

  def last_comment
    @last_comment || @last_comment = comments.order(:created_at, :updated_at).reverse_order.limit(1).first
  end

  def get_comments(all)
    result = comments.includes(
      direct_user: [user_badges: [:badge]]
    ).includes(:mentions)
    return result.where(hidden: false) if !all
    result
  end

  def description
    ""
  end

  def link
    '/thread/' + self.id.to_s + '-' + (self.safe_title.nil? ? '' : self.safe_title)
  end

  def location
    return '/view/' + self.owner_id.to_s if self.owner_type == 'Video'
    if self.owner_type == 'Report'
      return '/admin/report/view/' + self.owner_id.to_s
    end
    return '/message/' + self.id.to_s if self.owner_type == 'Pm'
    '/thread/' + self.id.to_s
  end

  def subscribed?(user)
    user && (self.thread_subscriptions.where(user_id: user.id).count > 0)
  end

  def subscribe(user)
    self.thread_subscriptions.create(user_id: user.id)
  end

  def unsubscribe(user)
    self.thread_subscriptions.where('user_id = ?', user.id).destroy_all
  end

  def toggle_subscribe(user)
    return false if !user
    if self.subscribed?(user)
      self.unsubscribe(user)
      return false
    end
    self.subscribe(user)
    true
  end

  def bump(sender, params, comment)
    recievers = self.thread_subscriptions.pluck(:user_id) - [sender.id]
    if self.owner_type == 'Report'
      if state = params[:report_state]
        @report = self.owner
        if state == 'open'
          if !@report.resolved.nil?
            @report.resolved = nil
            Notification.notify_admins(@report, "Report <b>" + self.title + "</b> has been reopened", self.location)
          end
        elsif state == 'close'
          if @report.resolved != false
            @report.resolved = false
            Notification.notify_admins(@report, "Report <b>" + self.title + "</b> has been closed", self.location)
          end
        elsif state == 'resolve'
          if !@report.resolved
            @report.resolved = true
            Notification.notify_admins(@report, "Report <b>" + self.title + "</b> has been marked as resolved", self.location)
          end
        end
        @report.save
      end
      Notification.notify_recievers(recievers, @report,
                                    sender.username + " has posted a reply to <b>" + self.title + "</b>", self.location)
    elsif self.owner_type == 'Pm'
      self.owner.bump(sender, comment)
    else
      if sender.subscribe_on_reply? && !self.subscribed?(sender)
        self.subscribe(sender)
      end
      Notification.notify_recievers(recievers, self, sender.username + " has posted a reply to <b>" + self.title + "</b>", self.location)
    end
  end
end
