require 'digest/md5'
require 'open3'

class Ffprobe

  SQUARE_CROP_COM = Ffmpeg.escape_filter_par('crop=min(iw,ih):min(iw,ih)').freeze

  def self.length(file)
    attribute(file, "duration")
  end

  def self.width(file)
    attribute(file, "width")
  end

  def self.height(file)
    attribute(file, "height")
  end

  def self.framerate(file)
    attribute(file, "avg_frame_rate")
  end

  def self.dimensions(file)
    [ width(file), height(file) ]
  end

  def self.frames(file)
    out = run_command('ffmpeg', '-hide_banner', '-i', file, '-map', '0:v:0', '-c', 'copy', '-f', 'null', '-', '2>&1 | grep \'frame=\'')
    return 0 if !out.include?('frame= ')
    out.split('frame= ')[1].to_i
  end

  def self.attribute(file, attr)
    output = probe("stream", file, attr)
    if output == 0
      output = probe("format", file, attr)
    end

    output.floor
  end

  private
  def self.probe(variant, file, field)
    stdout, error_str, status = Open3.capture3('ffprobe', '-v', 'error', '-show_entries', "#{variant}=#{field}", '-of', 'default=noprint_wrappers=1:nokey=1', file.to_s)
    stdout = stdout.split("\n")[0] || ''

    return stdout.to_i if !stdout.include?('/')
    stdout = stdout.split('/').map{|i| i.to_i }

    return stdout[0] if stdout[1] <= 0
    stdout[0] / stdout[1]
  end

  def self.run_command(*com)
    com = com.map{|i| i.to_s}
    puts "FFPROBE RUN: #{com}"
    stdout, error_str, status = Open3.capture3(com.join(' '))
    stdout
  end
end
