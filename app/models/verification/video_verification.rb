module Verification
  class VideoVerification

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
  end
end