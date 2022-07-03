require 'open3'

class Ffstream
  def self.produce(input, output_format)
    begin
      args = [
        'ffmpeg', '-hide_banner', '-nostats',
        '-i', input.to_s,
        '-f', output_format,
        '-movflags', 'frag_keyframe+empty_moov',
        '-'
      ]
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
    while c = io.gets
      len += c.length
      yield(c, len)
    end
    puts "Operation Ended, read #{len} bytes"
    len
  end

  def self.copy_streams(io_in, stream_out)
    read_as_lines(io_in){|c, len| stream_out.write c }
  end
end
