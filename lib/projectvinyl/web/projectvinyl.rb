module ProjectVinyl
  module Web
    class Projectvinyl
      def self.is_video_link(url)
        if url.nil? || (url = url.strip).empty?
          return false
        end
        !(url =~ /http?(s):\/\/(www.|)(projectvinyl\.[^\/]+(\/videos|)\/)([0-9]+)/).nil?
      end

      def self.embed_url(url)
        "/embed/#{video_id(url)}"
      end

      def self.video_id(url)
        url.split('?')[0].split('/').last.split(/[^0-9]/)[0]
      end
    end
  end
end
