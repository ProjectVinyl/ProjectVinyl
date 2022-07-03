require 'open3'

class Ffstream
  def self.produce(input, output_format)
    begin
      IO.popen([
        'ffmpeg', '-hide_banner', '-nostats', '-loglevel', 'panic', '-y',
        '-i', input.to_s,
        '-f', output_format,
        '-movflags',
        'frag_keyframe+empty_moov',
        '-'
      ]) do |io|
        yield(io)
        io.close
      end
    rescue Exception => e
      puts e
      puts e.backtrace
    end
  end

  def self.read_as_lines(io)
    len = 0
    while line = io.gets
      len += line.length
      yield(line)
    end
    puts "Operation Ended, read #{len} bytes"
    len
  end

  def self.copy_streams(io_in, stream_out)
    read_as_lines(io_in){|line| stream_out.write line}
  end
end
