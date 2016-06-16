class Mimes
   def self.safe_invert(hash)
     hash.each_with_object({}) do |(key,value),out|
       out[value] ||= key
     end
   end
   
   MIME_TYPES = self.safe_invert(Rack::Mime::MIME_TYPES)
   
   def self.ext(mime)
     return MIME_TYPES[mime]
   end
   
   def self.mime(ext)
     return Rack::Mime::MIME_TYPES[ext]
   end
end