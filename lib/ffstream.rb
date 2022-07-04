require 'open3'

class Ffstream
  DEFAULT_FORMAT_ARGS = {
    speed: %w[-minrate 54k -maxrate 72k -vf scale=-1:360 -movflags frag_keyframe+empty_moov+faststart],
    quality: %w[-q:v 10 -q:a 10 -movflags frag_keyframe+empty_moov]
  }.freeze
  CUSTOM_FORMAT_ARGS = {
    speed: {
      webm: %w[-vf scale=-1:720 -vcodec libvpx -deadline realtime],
      ogv: %w[-q:v 5 -q:a 3 -minrate 54k -maxrate 72k -vf scale=-1:720 -movflags frag_keyframe+empty_moov+faststart]
    },
    quality: {
    }
  }.freeze

  def self.format_flags(output_format, optimize_for: :quality)
    CUSTOM_FORMAT_ARGS[optimize_for][output_format.to_sym] || DEFAULT_FORMAT_ARGS[optimize_for]
  end

  def self.produce(input, output_format, optimize_for: :quality)
    begin
      args = %w[ffmpeg -hide_banner -nostats -i]
      args += [input.to_s, '-f', output_format]
      args += format_flags(output_format, optimize_for: optimize_for)
      args << '-'
      puts "FFMPEG: #{args.join(' ')}"
      IO.popen args do |io|
        puts "Starting stream worker at pid #{io.pid}"
        begin
          yield(io)
        rescue Exception => e
          puts "Killing stream worker #{io.pid} due to #{e}"
          Process.kill('KILL', io.pid)
        end
      ensure
        io.close
      end
    rescue Exception => e
      puts e
      puts e.backtrace
    end
  end

  def self.read_as_lines(io)
    len = 0
    while s = io.gets
      len += s.length
      yield(s)
    end
    puts "Operation Ended, read #{len} bytes"
    len
  end

  def self.copy_streams(io_in, stream_out)
    read_as_lines(io_in){|c| stream_out.write c }
  end
end
