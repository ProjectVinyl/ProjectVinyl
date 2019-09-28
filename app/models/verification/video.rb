module Verification
  class Video

    def self.ensure_uniq(data)
      if data
        hash = Ffmpeg.compute_checksum(data)
        if Video.where(checksum: hash).count == 0
          return { valid: true, value: hash }
        end
      end
      { valid: false }
    end

    def self.rebuild_queue
      webms = []
      location = Rails.root.join('public', 'stream')
      Dir.entries(location.to_s).each do |name|
        next unless name.index('.')
        split = name.split('.')
        if (id = split[0].to_i) && id > 0
          webms << id if split[1] == 'webm'
        end
      end
      workings = []
      location = Rails.root.join('encoding')
      Dir.entries(location.to_s).each do |name|
        next unless name.index('.')
        split = name.split('.')
        next unless (id = split[0].to_i) && id > 0
        if split[1] == 'webm'
          webms << id
          workings << id
        end
      end
      Video.where('id NOT IN (?) AND audio_only = false', webms).update_all(processed: nil)
      Video.where('id IN (?)', workings).update_all(processed: false)
      Video.where(processed: nil, hidden: false).count # return count
    end

    def self.build_file_list(location)
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

    def self.find_missing_file_ids(files)
      {
        webm: Video.where('id NOT IN (?)', files[:sources].uniq),
        sources: Video.where('audio_only = false AND id NOT IN (?)', files[:webms].uniq)
      }
    end

    def self.verify_integrity(report)
      public_files = self.build_file_list(Rails.root.join('public', 'stream'))
      private_files = self.build_file_list(Rails.root.join('private', 'stream'))

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
end