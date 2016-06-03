class Ffmpeg
  
   def self.getVideoLength(file)
     output = `ffprobe -v error -show_entries stream=duration -of default=noprint_wrappers=1:nokey=1 "#{file}"`
     output = output.to_i
     if output == 0
       output = `ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 "#{file}"`
     end
     return output.to_i.floor
   end
   
   def self.produceWebM(file)
     webm = file.split('.')[0] + '.webm'
     `ffmpeg -i  "#{file}" -c:v libvpx -crf 10 -b:v 1M -c:a libvorbis "#{webm}"`
   end
   
   def self.extractThumbnail(source, destination)
     output = `ffmpeg -i "#{source}" -ss 00:00:1 -vframes 1 "#{destination}"`
   end
end