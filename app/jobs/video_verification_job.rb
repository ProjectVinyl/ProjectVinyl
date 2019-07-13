class VideoVerificationJob < ApplicationJob
  queue_as :default

  def perform(user_id)
    Report.report_on(
      "System Integrity Report #{Time.zone.now}",
      "Action 'System Integrity Report' has been completed",
      { user_id: user_id, first: "System", other: "Working..." }
    ) do |report|
      report.other = ""
      Verification::Video.verify_integrity(report)
    end
  end
end