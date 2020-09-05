require 'projectvinyl/web/youtube'
require 'projectvinyl/web/peertube'
require 'projectvinyl/web/dailymotion'
require 'projectvinyl/web/projectvinyl'

module ProjectVinyl
  module Bbc
    class EmbedGenerator
      def self.generate_embed(tag)
        return to_iframe(Web::Youtube.embed_url(tag.inner_text)) if Web::Youtube.is_video_link(tag.inner_text)
        return to_iframe(Web::Peertube.embed_url(tag.inner_text)) if Web::Peertube.is_video_link(tag.inner_text)
        return to_iframe(Web::Dailymotion.embed_url(tag.inner_text)) if Web::Dailymotion.is_video_link(tag.inner_text)
        return to_iframe(Web::Projectvinyl.embed_url(tag.inner_text)) if Web::Projectvinyl.is_video_link(tag.inner_text)
        tag.outer_bbc
      end

      def self.to_iframe(url)
        "<iframe allowfullscreen class=\"embed\" src=\"#{url}\"></iframe>"
      end
    end
  end
end
