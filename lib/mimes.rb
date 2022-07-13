require 'webrick/httputils'

class Mimes
  def self.load_from_file(path)
    return {} if !File.exist?(path)
    WEBrick::HTTPUtils.load_mime_types(path).each_with_object({}) do |(key, value), out|
      key = '.' + key if key.index('.') != 0
      out[key] = value
    end
  end

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

  def self.all
    EXT_TO_MIME
  end

  OS_DEFINED = self.load_from_file('/etc/mime.types')
  EXT_TO_MIME = Rack::Mime::MIME_TYPES.merge!(OS_DEFINED).merge!({
    '.mkv' => 'video/x-matroska',
    '.aac' => 'audio/aac',
    '.flac' => 'audio/flac',
    '.avif' => 'image/avif',
    '.avi' => 'video/x-msvideo',
    '.bmp' => 'image/bmp', # Keep as the official IANA type (from image/x-ms-bmp) https://bugs.python.org/issue22589
    '.mid' => 'audio/midi',
    '.midi' => 'audio/midi',
    '.ogg' => 'audio/ogg',
    '.opus' => 'audio/ogg',
    '.weba' => 'audio/webm',
    '.webp' => 'image/webp'
  })
  MIME_TO_EXT = EXT_TO_MIME.each_with_object({}){|(key, value), out| out[value] ||= key }.merge!({
    'image/x-ms-bmp' => '.bmp' # Map from unofficial to extension
  })
end
