module ProjectVinyl
  module Web
    class Dailymotion
      def self.is_video_link(url)
        if url.nil? || (url = url.strip).empty?
          return false
        end
        !(url =~ /http?(s):\/\/(www\.)(dailymotion\.[^\/]+(\/embed|)\/video\/)([^&]+)/).nil?
      end

      def self.embed_url(url)
        "https://www.dailymotion.com/embed/video/#{video_id(url)}"
      end

      def self.video_id(url)
        return url.split('?')[0].split('/video/').last if url.index('/video/')
        ''
      end
    end
  end
end
