class Mimes
  def self.safe_invert(hash)
    hash.each_with_object({}) do |(key, value), out|
      out[value] ||= key
    end
  end

  EXT_TO_MIME = Rack::Mime::MIME_TYPES.merge({
    '.mkv' => 'video/x-matroska',
    '.aac' => 'audio/aac',
    '.flac' => 'audio/flac',
    '.avif' => 'image/avif',
    '.avi' => 'video/x-msvideo',
    '.bmp' => 'image/bmp',
    '.mid' => 'audio/midi',
    '.midi' => 'audio/midi',
    '.ogg' => 'audio/ogg',
    '.opus' => 'audio/opus',
    '.weba' => 'audio/webm',
    '.webp' => 'image/webp'
  })
  MIME_TO_EXT = self.safe_invert(EXT_TO_MIME)

  def self.media_ext(media)
    ext = File.extname(media.original_filename)
    return Mimes.ext(media.content_type) if ext.blank?
    return ext
  end

  def self.ext(mime)
    MIME_TO_EXT[mime]
  end

  def self.mime(ext)
    EXT_TO_MIME['.' + ext.gsub(/^\.+/, '')]
  end
end
