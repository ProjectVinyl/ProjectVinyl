module Albums
  module Item
    extend ActiveSupport::Concern
    included do
      extend Forwardable
      def_delegator :album, :virtual?
      def_delegator :album, :owned_by
      def_delegator :video, :tiny_thumb
    end

    def user
      direct_user || @dummy || (@dummy = User.dummy(video.user_id))
    end

    def link
      "#{video.link}?#{ref}"
    end

    def ref
      "list=#{album_id}&index=#{index}"
    end

    def tooltip
      video.hidden ? "hidden" : "#{video.title} - #{video.user.username}"
    end

    def title
      video.hidden ? "hidden" : video.title
    end
  end
end
