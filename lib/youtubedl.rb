require 'digest/md5'
require 'open3'

class Youtubedl
  def self.video_meta(src)
    temp_dir = Rails.root.join('temp/youtubedl')
    temp_dir.mkdir
    Dir.chdir(temp_dir) do
      stdout, error_str, status = Open3.capture3('yt-dlp', src, '--dump-json', '--write-pages', '-o', Rails.root.join('encoding/temp').to_s)
      return {error: error_str} if !error_str.empty?
      json = JSON.parse(stdout, symbolize_names: true)
      pages = Dir.glob("#{temp_dir.to_s}/#{json[:id]}*")
      json[:__coppa] = pages.filter{ |page| /.*"Try Youtube Kids".*/im.match?(File.read(file)) }.present?
      pages.each(&FileUtils.method(:remove_entry))
      end
    end
  end

  def self.download_video(src, dest)
    Open3.capture3('yt-dlp', src, '-o', dest)
  end
end
