class VerificationJob < ActiveJob::Base
  queue_as :default

  def perform(user_id)
    user_component = User.verify_integrity

    report = Report.new(user_id: user_id, first: "System", other: "Working...", resolved: nil)
    report.comment_thread = CommentThread.create!(user_id: user_id, title: "System Integrity Report #{Time.zone.now}")
    report.other = ""
    report.write("User avatars reset: " + user_component[0].to_s)
    report.write("User banners reset: " + user_component[1].to_s)
    Video.verify_integrity(report) # fixme, but will save the report for us
    Notification.notify_admins(report, "Action \"System Integrity Report\" has been completed", report.comment_thread.location)
  end
end
