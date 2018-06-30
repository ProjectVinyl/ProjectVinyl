require 'digest/md5'
require 'open3'

class Ffmpeg
  def self.escape_filter_par(par)
    par.gsub(/([\(\),])/, '\\\\\1')
  end
  
  HEADER = ['ffmpeg', '-hide_banner', '-nostats', '-loglevel', 'panic', '-y'].freeze
  SQUARE_CROP_COM = escape_filter_par('crop=min(iw,ih):min(iw,ih)').freeze
  SQUARE_TWO_FORTY = escape_filter_par('scale=min(min(iw,ih),240):min(min(iw,ih),240)').freeze
  SCALE_ONE_THIRTY = 'scale=-1:130'.freeze
  
  def self.compute_checksum(data)
    Digest::MD5.hexdigest(data)
  end
  
  def self.get_video_length(file)
    output = probe("stream", file)
    if output == 0
      output = probe("format", file)
    end
    output.floor
  end
  
  def self.cycle_lock(file, unlock)
    webm = file.to_s.split('.')[0] + '.webm'
    temp = Rails.root.join('encoding', File.basename(webm).to_s).to_s
    if File.exist?(temp) && File.mtime(temp) < Time.now.ago(1800)
      File.rename(temp, webm) if unlock
      yield
      return true
    end
    false
  end
  
  def self.locked?(file)
    cycle_lock(file, false) do
      yield if block_given?
    end
  end
  
  def self.try_unlock?(file)
    cycle_lock(file, true) do
      yield if block_given?
    end
  end
  
  def self.produce_webm(file)
    webm = "#{file.to_s.split('.')[0]}.webm"
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
        puts "Existing file found (#{temp})"
        return "Conversion Complete (Unlocked Index)"
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
          puts "Conversion complete (#{file})"
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
  
  def self.to_h_m_s(length)
    h = length / 3600
    m = (length / 60) % 60
    s = length % 60
    yield(h, m, s) if block_given?
    format("%02d:%02d:%02d", h, m, s)
  end
  
  def self.from_h_m_s(hms)
    hms = hms.split(':').map(&:to_f)
    hms.unshift 0 while hms.length < 3
    (hms[0] * 3600) + (hms[1] * 60) + hms[2]
  end
  
  def self.crop_avatar(src, dst)
    run_command('-i', src, '-vf', "#{SQUARE_CROP_COM},#{SQUARE_TWO_FORTY}", dst)
  end
  
  def self.crop_square(src, dst)
    run_command('-i', src, '-vf', SQUARE_CROP_COM, dst)
  end
  
  def self.scale(src, dst, *args)
    args << args[0] if args.length == 1
    run_command('-i', src, '-vf', escape_filter_par("scale=#{args[0]}:#{args[1]}"), dst)
  end
  
  def self.extract_thumbnail(src, dst_full, dst_sml, time)
    time = to_h_m_s(time)
    run_command('-i', src, '-ss', time, '-vframes', 1, dst_full, '-ss', time, '-vframes', 1, '-vf', SCALE_ONE_THIRTY, dst_sml)
  end
  
  def self.extract_tiny_thumb_from_existing(src, dst)
    run_command(src, '-vf', SCALE_ONE_THIRTY, dst)
  end
  
  private
  def self.probe(variant, file)
    stdout, error_str, status = Open3.capture3('ffprobe', '-v', 'error', '-show_entries', "#{variant}=duration", '-of', 'default=noprint_wrappers=1:nokey=1', file.to_s)
    stdout.to_i
  end
  
  def self.run_command(*com)
    com = HEADER + com.map{|i| i.to_s}
    puts "FFMPEG RUN: #{com}"
    system *com
  end
end
