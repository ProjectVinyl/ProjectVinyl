class Report < ActiveRecord::Base
  belongs_to :direct_user, class_name: "User", foreign_key: "user_id"
  belongs_to :video

  has_one :comment_thread, as: :owner, dependent: :destroy

  def self.on(sender, msg)
    if true || !Report.where('created_at > ?', Time.zone.now.yesterday.beginning_of_day).first
      report = Report.create(user_id: sender.id, first: "System", other: "Working...", resolved: false)
      report.comment_thread = CommentThread.create(user_id: sender.id, title: "#{msg} (#{Time.zone.now})")
      report.save
      Thread.start do
        begin
          yield(report)
        rescue Exception => e
          report.write("Action did not complete correctly. <br>#{e}")
          puts e
          puts e.backtrace
        ensure
          report.resolved = nil
          Notification.notify_admins(report, "Action \"#{msg}\" has been completed", report.comment_thread.location)
          report.save
          ActiveRecord::Base.connection.close
        end
      end
      return true
    end
    false
  end

  def user
    self.direct_user || @dummy || (@dummy = User.dummy(self.user_id))
  end

  def user=(user)
    self.direct_user = user
  end

  def write(msg)
    self.other << "<br>#{msg}"
  end
end
