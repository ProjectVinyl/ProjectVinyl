module Albums
  module Item
    def tiny_thumb(user, filter)
      video.tiny_thumb(user, filter)
    end

    def owned_by(user)
      album.owned_by(user)
    end

    def user
      direct_user || @dummy || (@dummy = User.dummy(self.video.user_id))
    end

    def link
      "#{video.link}?#{ref}"
    end

    def ref
      "list=#{album_id}&index=#{index}"
    end

    def virtual?
      album.virtual?
    end

    def tooltip
      video.hidden ? "hidden" : "#{video.title} - #{video.user.username}"
    end

    def title
      video.hidden ? "hidden" : video.title
    end
  end
end
