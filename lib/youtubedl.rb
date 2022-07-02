require 'digest/md5'
require 'open3'

class Youtubedl
  def self.video_meta(src)
    stdout, error_str, status = Open3.capture3('yt-dlp', src, '--dump-json')
    return {error: error_str} if !error_str.empty?
    JSON.parse(stdout, symbolize_names: true)
  end

  def self.download_video(src, dest)
    Open3.capture3('yt-dlp', src, '-o', dest)
  end
end
