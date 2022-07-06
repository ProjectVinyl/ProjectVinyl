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

  def self.to_h_m_s(length, cut_leading_zero_hours: false)
    h = length / 3600
    m = (length / 60) % 60
    s = length % 60
    yield(h, m, s) if block_given?
    return format("%02d:%02d", m, s) if h == 0 && cut_leading_zero_hours
    format("%02d:%02d:%02d", h, m, s)
  end

  def self.to_h_m_s_accurate(length)
    length = length.to_f

    h = length / 3600
    m = (length / 60) % 60
    s = length % 60
    yield(h, m, s) if block_given?
    format("%02d:%02d:%02f", h, m, s)
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

  def self.run_command(*com)
    com = HEADER + com.map{|i| i.to_s}
    puts "FFMPEG RUN: #{com}"
    if block_given?
      return wait_on(*com) do
        yield
      end
    end
    system *com
  end

  def self.wait_on(*com)
    begin
      IO.popen(com) do |io|
        begin
          while line = io.gets
            line.chomp!
          end
          io.close
          yield if block_given?
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
  end
end
