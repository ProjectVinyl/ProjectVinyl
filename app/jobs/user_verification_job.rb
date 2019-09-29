class UserVerificationJob < ApplicationJob
  queue_as :default

  def perform(user_id)
    Report.report_on(
      "System Integrity Report #{Time.zone.now}",
      "Action 'System Integrity Report' has been completed",
      { user_id: user_id, first: "System", other: "Working..." }
    ) do |report|
      report.other = ""
      verify_integrity(report)
    end
  end

  def verify_integrity(report)
    avatars_reset = 0
    banners_reset = 0

    User.all.find_each do |u|
      avatar_exists = File.exist?(u.avatar_path)

      if u.mime.nil? != avatar_exists
        u.mime = avatar_exists ? 'png' : nil
        u.save
        avatars_reset += 1
      end

      banner_exists = File.exist?(u.banner_path)

      if u.banner_set != banner_exists
        u.banner_set = banner_exists
        u.save
        banners_reset += 1
      end
    end

    report.write("User avatars reset: #{avatars_reset}")
    report.write("User banners reset: #{banners_reset}")
  end
end
