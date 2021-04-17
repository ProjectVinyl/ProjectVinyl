module Albums
  class VideoSet

    def initialize(owner)
      @owner = owner
    end

    def current_index(defau)
      defau
    end

    def current(defau)
      defau
    end

    def sample(filter)
      @owner.ordered(@owner.videos.where(id: ids_from_filter(filter)).limit(4))
    end

    def toggle(video)
      if (item = @owner.album_items.where(video_id: video.id).first)
        item.destroy
        video.update_index
        return false
      end
      add(video)
      true
    end

    def add(video)
      index = @owner.album_items.length
      album_items.create(video_id: video.id, index: index, o_video_id: video.id)
      repaint_ordering(album_items)
      video.update_index
    end

    def all(filter)
      @items ||= @owner.ordered(@owner.album_items.where(video_id: ids_from_filter(filter)).includes(:direct_user, video: :tags))
    end

    def next(filter, current)
      all(filter).following(current).first
    end

    def previous(filter, current)
      all(filter).leading(current).last
    end

    def virtual?
      false
    end

    private
    def ids_from_filter(filter)
      filter.videos.where(hidden: false, duplicate_id: 0, albums: [ @owner.id ]).ids
    end
  end
end
