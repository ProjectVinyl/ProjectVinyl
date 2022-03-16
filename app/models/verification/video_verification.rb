module Verification
  class VideoVerification
    def self.ensure_uniq(data, excluded_id=-1)
      if data
        hash = Ffmpeg.compute_checksum(data)
        if Video.where(checksum: hash).where.not(id: excluded_id).count == 0
          return { valid: true, value: hash, data: data }
        end
      end
      { valid: false }
    end
  end
end
