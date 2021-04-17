module Albums
  class VirtualVideoSet
    attr_reader :query, :id, :user, :videos, :album_items

    def initialize(query, current, index, current_filter)
      @current = current
      @filter = current_filter
      @index = [0, index].max
      @query = query.strip

      @album_items = []
      @videos = []
      @user = User.dummy(0)

      if @query.present?
        fetch_items.each_with_index do |item, i|
          @videos << item
          @album_items << Albums::VirtualItem.new(self, item, i)

          if item.id == current.id
            @current = item
            @index = i
          end
        end
      end
    end

    def current_index(defau)
      @index
    end

    def current(defau)
      @current || (@videos.length ? @videos.first : defau)
    end

    def toggle(_video)
      false
    end

    def add(_video)
      item = AlbumItem.new
      @videos << item
    end

    def all(filter)
      @album_items
    end

    def next(filter, current)
      return nil if @album_items.empty? || current >= @album_items.length - 1
      @album_items[current + 1]
    end

    def previous(filter, current)
      return nil if @album_items.empty? || current < 1
      @album_items[(current - 1) % @album_items.length]
    end

    def virtual?
      true
    end

    private
    def fetch_items
      @filter.videos
        .must(@filter.build_params(@query).to_hash)
        .where(hidden: false, duplicate_id: 0, listing: 0)
        .order(:created_at)
        .limit(@index + 5)
        .records
    end
  end
end
