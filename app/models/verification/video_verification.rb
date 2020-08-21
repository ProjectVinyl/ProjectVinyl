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
  end
end