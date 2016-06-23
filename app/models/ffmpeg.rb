class Ffmpeg
  
   def self.getVideoLength(file)
     output = `ffprobe -v error -show_entries stream=duration -of default=noprint_wrappers=1:nokey=1 "#{file}"`
     output = output.to_i
     if output == 0
       output = `ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 "#{file}"`
     end
     return output.to_i.floor
   end
   
   def self.getFrameRate(file)
     output = `ffprobe -v error -select_streams v:0 -show_entries stream=avg_frame_rate -of default=noprint_wrappers=1:nokey=1 "#{file}"`
     return output.to_s.split('/')[0].to_i
   end
   
   def self.getFrameCount(file)
     rate = Ffmpeg.getFrameRate(file)
     duration = Ffmpeg.getVideoLength(file)
     return rate * duration
   end
   
   def self.produceWebM(file)
     webm = file.split('.')[0] + '.webm'
     temp = Rails.root.join('encoding', File.basename(webm).to_s).to_s
     if File.exists?(webm)
       return 1
     end
     if File.exists?(temp) || !File.exists?(file)
       return -1
     end
     `ffmpeg -i  "#{file}" -c:v libvpx -crf 10 -b:v 1M -c:a libvorbis "#{temp}"`
     File.rename(temp, webm)
     return 0
   end
   
   def self.extractThumbnail(source, destination)
     duration = Ffmpeg.getVideoLength(source).to_f / 2
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
     seconds = length.to_i
     temp = destination.to_s + ".png"
     output = `ffmpeg -y -i "#{source}" -ss #{hours}:#{minutes}:#{seconds} -vframes 1 "#{temp}"`
     File.rename(temp, destination)
   end
end