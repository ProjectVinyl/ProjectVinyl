class VideoVerificationJob < ApplicationJob
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

  def build_file_list(location)
    webms = []
    sources = []

    Dir.entries(location.to_s).each do |name|
      next unless name.index('.')

      split = name.split('.')
      id = split[0].to_i

      if id && id > 0
        if split[1] == 'webm'
          webms << id
        else
          sources << id
        end
      end
    end

    { webm: webms, sources: sources }
  end

  def find_missing_file_ids(files)
    {
      webm: Video.where('id NOT IN (?)', files[:sources].uniq),
      sources: Video.where('audio_only = false AND id NOT IN (?)', files[:webms].uniq)
    }
  end

  def verify_integrity(report)
    public_files = build_file_list(Rails.root.join('public', 'stream'))
    private_files = build_file_list(Rails.root.join('private', 'stream'))

    public_files[:webms] += private_files[:webms]
    public_files[:sources] += private_files[:sources]

    lost_files = find_missing_file_ids(public_files)

    total = Video.all.count

    report.write("Missing video files: #{lost_files[:sources].count}")
    lost_files[:sources].each do |v|
      report.write("  #{v}")
    end

    report.write("Missing webm files : #{lost_files[:webms].count}")
    lost_files[:webms].each do |v|
      report.write("  #{v}")
    end
  end
end
