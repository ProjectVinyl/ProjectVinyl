class Ffmpeg
  
   def self.getVideoLength(file)
     output = `ffprobe -v error -show_entries stream=duration -of default=noprint_wrappers=1:nokey=1 "#{file}"`
     output = output.to_i
     if output == 0
       output = `ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 "#{file}"`
     end
     return output.to_i.floor
   end
end