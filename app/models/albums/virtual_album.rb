module Albums
  class VirtualAlbum
    include Album
    attr_accessor :id, :user, :title, :safe_title, :description
    attr_reader :video_set

    def_delegator :video_set, :videos
    def_delegator :video_set, :album_items

    def initialize(query, current, index, current_filter)
      id = 0
      title = "Mix - #{query}"
      safe_title = title
      description = ""
      @video_set = Albums::VirtualVideoSet.new(query, current, index, current_filter)
    end

    def owned_by(_user)
      false
    end

    def transfer_to(user)
    end

    def link
      "#{video_set.current.link}?q=#{video_set.query}&index=#{video_set.current_index}"
    end
  end
end
