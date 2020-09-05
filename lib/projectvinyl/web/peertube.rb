module ProjectVinyl
  module Web
    class Peertube
      def self.is_video_link(url)
        if url.nil? || (url = url.strip).empty?
          return false
        end
        !(url =~ /http?(s):\/\/(vault.mle.party\/videos(\/embed|)\/)([^&]+)/).nil?
      end

      def self.embed_url(url)
        "https://vault.mle.party/videos/embed/#{video_id(url)}"
      end

      def self.video_id(url)
        return url.split('?')[0].split('/').last if url.index('/videos/')
        ''
      end
    end
  end
end
