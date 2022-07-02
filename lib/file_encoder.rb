class FileEncoder
  SHEET_MAX_SIDE = 20
  SHEET_SIZE = SHEET_MAX_SIDE * SHEET_MAX_SIDE
  ARGS_BY_FORMAT = {
    webm: '-c:v libvpx -crf 10 -b:v 1M -c:a libvorbis',
    mp4: '-vcodec libx264 -strict -2',
    mp3: ''
  }.freeze

  def self.create_temp_path(filename, input, output)
    if !File.exist?(input)
      yield(nil)
      return "File Not Found"
    end

    temp = Rails.root.join('encoding', filename).to_s

    if File.exist?(temp)
      if File.mtime(temp) < Time.now.ago(1800)
        FileUtils.mv(temp, output)
        yield(nil)
        puts "Existing file found (#{temp})"
        return "Conversion Complete (Unlocked Index)"
      end
    end

    yield(temp)

    "Conversions Started"
  end

  def self.prepare(filename, input, output, &block)
    FileUtils.mkdir_p(File.dirname(output))

    if File.exist?(output)
      yield(nil)
      return "Completed"
    end

    create_temp_path(filename, input, output, &block)
  end

  def self.encode_file(record, input, output, ext)
    prepare("#{record.id}.#{ext}", input, output) do |temp|
      return yield if block_given? && temp.nil?
      Ffmpeg.wait_on(Rails.root.join('encode').to_s, input.to_s, temp.to_s, output.to_s, ARGS_BY_FORMAT[ext.to_sym]) do
        puts "Conversion complete (#{output})"
        yield if block_given?
      end
    end
  end

  def self.extract_tile_sheet(record, input, output)
    create_temp_path("frames_#{record.id}", input, output) do |temp|
      return yield if temp.nil?
      FileUtils.mkdir_p(temp)

      frame_count = Ffprobe.frames(input) / 20
      rows = SHEET_MAX_SIDE
      if (frame_count > 0 && frame_count <= SHEET_SIZE)
        rows = (frame_count.to_f / SHEET_MAX_SIDE).ceil
      end

      Ffmpeg.run_command('-vsync', 'vfr', '-i', input.to_s, '-q:v', 1, '-vf', "select=not(mod(n\\,20)),scale=-1:50,tile=#{SHEET_MAX_SIDE}x#{rows}", temp.to_s + "/sheet_%03d.jpg") do
        FileUtils.mv(temp, output)
        puts "Sprite Sheet complete (#{output})"
        yield
      end
    end
  end
end
