require 'digest/md5'

class Ffmpeg
  INPUT_WIDTH = 'iw'.freeze
  INPUT_HEIGHT = 'ih'.freeze
  HEADER = '-hide_banner -nostats -loglevel panic -y'.freeze

  def self.max_of(width, height)
    "max(#{width}\\,#{height})"
  end

  def self.min_of(width, height)
    "min(#{width}\\,#{height})"
  end

  def self.compute_checksum(data)
    Digest::MD5.hexdigest(data)
  end

  def self.get_video_length(file)
    output = `ffprobe -v error -show_entries stream=duration -of default=noprint_wrappers=1:nokey=1 "#{file}"`
    output = output.to_i
    if output == 0
      output = `ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 "#{file}"`
    end
    output.to_i.floor
  end

  def self.locked?(file)
    webm = file.to_s.split('.')[0] + '.webm'
    temp = Rails.root.join('encoding', File.basename(webm).to_s).to_s
    if File.exist?(temp)
      return true if File.mtime(temp) > Time.now.ago(1800)
    end
    false
  end

  def self.try_unlock?(file)
    webm = file.to_s.split('.')[0] + '.webm'
    temp = Rails.root.join('encoding', File.basename(webm).to_s).to_s
    if File.exist?(temp)
      if File.mtime(temp) < Time.now.ago(1800)
        File.rename(temp, webm)
        return true
      end
    end
    false
  end

  def self.produce_webm(file)
    webm = file.to_s.split('.')[0] + ".webm"
    temp = Rails.root.join('encoding', File.basename(webm).to_s).to_s
    if File.exist?(webm)
      yield
      return "Completed"
    end
    return "File Not Found" if !File.exist?(file)
    if File.exist?(temp)
      if File.mtime(temp) < Time.now.ago(1800)
        File.rename(temp, webm)
        yield
        puts 'Existing file found (' + temp.to_s + ')'
        return "Complete (Unlocked Index)"
      end
    end
    begin
      IO.popen([Rails.root.join('encode').to_s, file.to_s, temp, webm]) do |io|
        begin
          while line = io.gets
            line.chomp!
          end
          io.close
          yield
          puts 'Conversion complete (' + file.to_s + ')'
        rescue Exception => e
          puts e
          puts e.backtrace
        ensure
          ActiveRecord::Base.connection.close
        end
      end
    rescue Exception => e
      puts e
      puts e.backtrace
    end
    "Started"
  end

  def self.to_h_m_s(duration)
    hours = 0
    if duration >= 3600
      hours = (duration / 3600).floor.to_i
      duration = duration % 3600
    end
    minutes = 0
    if duration >= 60
      minutes = (duration / 60).floor.to_i
      duration = duration % 60
    end
    seconds = duration.to_i
    "#{hours}:#{minutes}:#{seconds}"
  end

  def self.from_h_m_s(hms)
    hms = hms.split(':').map(&:to_f)
    hms.unshift 0 while hms.length < 3
    (hms[0] * 3600) + (hms[1] * 60) + hms[2]
  end

  def self.extract_thumbnail(source, destination, time)
    time = Ffmpeg.to_h_m_s(time)
    `ffmpeg #{Ffmpeg::HEADER} -i "#{source}" -ss #{time} -vframes 1 "#{destination}.png" -ss #{time} -vframes 1 -vf scale=-1:130 "#{destination}-small.png"`
  end

  def self.crop_avatar(source, destination)
    `ffmpeg #{Ffmpeg::HEADER} -i "#{source}" -vf crop=min(iw\\,ih):min(iw\\,ih):(in_w-out_w)/2:(in_h-out_h)/2\\,scale=min(min(iw\\,ih)\\,240):min(min(iw\\,ih)\\,240) "#{destination}"`
  end

  def self.crop_square(source, destination)
    `ffmpeg #{Ffmpeg::HEADER} -i "#{source}" -vf crop=min(iw\\,ih):min(iw\\,ih):(in_w-out_w)/2:(in_h-out_h)/2 "#{destination}"`
  end

  def self.scale(source, destination, *args)
    args << args[0] if args.length == 1
    `ffmpeg #{Ffmpeg::HEADER} -i "#{source}" -vf scale=#{args[0]}:#{args[1]} "#{destination}"`
  end

  def self.extract_tiny_thumb_from_existing(png)
    IO.popen("ffmpeg -hide_banner -nostats -loglevel panic -i \"#{png}.png\" -vf scale=-1:130 \"#{png}-small.png\"")
  end
end
