require 'digest/md5'

class Ffmpeg
   def self.compute_checksum(data)
     return Digest::MD5.hexdigest(data)
   end
   
   def self.getVideoLength(file)
     output = `ffprobe -v error -show_entries stream=duration -of default=noprint_wrappers=1:nokey=1 "#{file}"`
     output = output.to_i
     if output == 0
       output = `ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 "#{file}"`
     end
     return output.to_i.floor
   end
   
   def self.locked?(file)
     webm = file.to_s.split('.')[0] + '.webm'
     temp = Rails.root.join('encoding', File.basename(webm).to_s).to_s
     if File.exist?(temp)
       if File.mtime(temp) > Time.now.ago(1800)
         return true
       end
     end
     return false
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
     return false
   end
   
   def self.produceWebM(file)
     webm = file.to_s.split('.')[0] + ".webm"
     temp = Rails.root.join('encoding', File.basename(webm).to_s).to_s
     if File.exist?(webm)
       yield
       return "Completed"
     end
     if !File.exist?(file)
       return "File Not Found"
     end
     if File.exist?(temp)
       if File.mtime(temp) < Time.now.ago(1800)
         File.rename(temp, webm)
         yield
         puts 'Existin file found (' + temp.to_s + ')'
         return "Complete (Unlocked Index)"
       end
     end
     begin
     IO.popen([Rails.root.join('encode').to_s, file.to_s, temp, webm]) {|io|
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
     }
     rescue Exception => e
       puts e
       puts e.backtrace
     end
     return "Started"
   end
   
   def self.to_h_m_s(duration)
     hours = 0
     if duration >= 3600
       hours = (duration/3600).floor.to_i
       duration = duration % 3600
     end
     minutes = 0
     if duration >= 60
       minutes = (duration/60).floor.to_i
       duration = duration % 60
     end
     seconds = duration.to_i
     return "#{hours}:#{minutes}:#{seconds}"
   end
   
   def self.from_h_m_s(hms)
    hms = hms.split(':').map do |t|
      t.to_f
    end
    while hms.length < 3
      hms.unshift 0
    end
    return (hms[0] * 3600) + (hms[1] * 60) + hms[2]
   end
   
   def self.extractThumbnail(source, destination, time)
     time = Ffmpeg.to_h_m_s(time)
     `ffmpeg -hide_banner -nostats -loglevel panic -y -i "#{source}" -ss #{time} -vframes 1 "#{destination}.png" -ss #{time} -vframes 1 -vf scale=-1:130 "#{destination}-small.png"`
   end
   
   def self.extractTinyThumbFromExisting(png)
     IO.popen('ffmpeg -hide_banner -nostats -loglevel panic -i "' + png.to_s + '.png" -vf scale=-1:130 "' + png.to_s + '-small.png"')
   end
end