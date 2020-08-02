class Mimes
  def self.safe_invert(hash)
    hash.each_with_object({}) do |(key, value), out|
      out[value] ||= key
    end
  end

  MIME_TYPES = self.safe_invert(Rack::Mime::MIME_TYPES)

  def self.media_ext(media)
    ext = File.extname(media.original_filename)
    return Mimes.ext(media.content_type) if ext.blank?
    return ext
  end

  def self.ext(mime)
    MIME_TYPES[mime]
  end

  def self.mime(ext)
    Rack::Mime::MIME_TYPES[ext]
  end
end
