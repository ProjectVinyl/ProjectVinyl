class VerificationJob < ApplicationJob
  queue_as :default

  def perform(user_id)
    report = Report.new(
      user_id: user_id,
      first: "System",
      other: "Working...",
      resolved: nil
    )
    report.comment_thread = CommentThread.create!(
      user_id: user_id,
      title: "System Integrity Report #{Time.zone.now}"
    )
    report.other = ""
    
    User.verify_integrity(report)
    Video.verify_integrity(report)
    
    report.save
    
    Notification.notify_admins(report, "Action \"System Integrity Report\" has been completed", report.comment_thread.location)
  end
end
