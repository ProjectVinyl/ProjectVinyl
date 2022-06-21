require 'digest/md5'
require 'open3'

class Youtubedl
  def self.video_meta(src)
    stdout, error_str, status = Open3.capture3('yt-dlp', src, '--dump-json')
    JSON.parse(stdout, symbolize_names: true)
  end
end
