require 'digest/md5'
require 'open3'

class Youtubedl
  def self.video_meta(src, include_end_screen: false)
    temp_dir = Rails.root.join("tmp/youtubedl/#{src.gsub(/[^a-zA-Z_-]/, '-')}")
    FileUtils.mkdir_p temp_dir
    json = Dir.chdir(temp_dir) do
      stdout, error_str, status = Open3.capture3('yt-dlp', src, '--dump-json', '--write-pages')
      return {error: error_str} if !error_str.empty?

      Open3.capture3('curl', src, '-o', 'curled.dump') if include_end_screen

      json = JSON.parse(stdout, symbolize_names: true)
      pages = Dir.glob("#{temp_dir.to_s}/*")

      json[:__coppa] = pages.filter{ |page| /.*"Try Youtube Kids".*/im.match?(File.read(page)) }.present?

      if include_end_screen
        json[:__endscreen] = pages.map{|page| find_endscreen(page)}
          .filter{|jank| jank.present?}
          .first || {}
      end

      json
    end

    FileUtils.remove_entry(temp_dir)
    json
  end

  def self.download_video(src, dest)
    Open3.capture3('yt-dlp', src, '-o', dest)
  end

  private
  def self.find_endscreen(path)
    Open3.pipeline_r(
      ['sed', '-nr', 's%.*"endscreen"\:([^;]*);.*%\1%p', path],
      ['jq', '.', '-r', '-c', '-M']
    ) do |io|
      json = ''
      while s = io.gets
        json += s
      end
      json = json.chomp!
      return nil if json == 'null'
      if json.present?
        json = JSON.parse(json, symbolize_names: true)
        return json[:endscreenRenderer]
      end
      nil
    ensure
      io.close
    end
  end
end
