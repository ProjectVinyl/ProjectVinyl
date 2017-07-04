class RecreateIndexJob < ApplicationJob
  queue_as :default

  def perform(user_id, table)
    table = table.constantize
    table.__elasticsearch__.delete_index!
    table.__elasticsearch__.create_index!
    table.import

    report = Report.create!(user_id: user_id, first: "System", other: "Complete.", resolved: nil)
    report.comment_thread = CommentThread.create!(user_id: user_id, title: "Indexing table #{table} (#{Time.zone.now})")
    report.save!
    Notification.notify_admins(report, "Action \"Recreate #{table} Index\" has been completed", report.comment_thread.location)
  end
end
