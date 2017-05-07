class Report < ActiveRecord::Base
  belongs_to :direct_user, class_name: "User", foreign_key: "user_id"
  belongs_to :video
  
  has_one :comment_thread, as: :owner, dependent: :destroy
  
  def self.on(sender, msg)
    if !(Report.where('created_at > ?', Time.zone.now.yesterday.beginning_of_day).first)
      report = Report.create(user_id: sender.id, first: "System", other: "Working...", resolved: false)
      report.comment_thread = CommentThread.create(user_id: sender.id, title: 'System Integrity Report (' + Time.zone.now.to_s + ')')
      report.save
      Thread.start {
        begin
          yield(report)
        rescue Exception => e
          report.other << "<br>Action did not complete correctly. <br>" + e.to_s
          puts e
          puts e.backtrace
        ensure
          report.resolved = nil
          Notification.notify_admins(report, msg, report.comment_thread.location)
          report.save
          ActiveRecord::Base.connection.close
        end
      }
      return true
    end
    return false
  end
  
  def user
    return self.direct_user || @dummy || (@dummy = User.dummy(self.user_id))
  end
  
  def user=(user)
    self.direct_user = user
  end
end
