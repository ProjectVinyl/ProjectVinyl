class VirtualAlbum < Album
  attr_reader :query, :videos

  def initialize(query, current, index, current_filter)
    @current = current
    @filter = current_filter
    @index = [0, index].max
    @offset = 0 #[0, @index - 20].max
    @query = query.strip

    @items = []
    @videos = []

    if @query.present?
      self.fetch_items.each_with_index do |item, i|
        @videos << item
        @items << VirtualAlbumItem.new(self, item, @offset + i)
        
        if item.id == current.id
          @current = item
          @index = i
        end
      end
    end
  end

  def user
    User.dummy(0)
  end

  def id
    0
  end

  def title
    "Mix - #{@query}"
  end

  def safe_title
    self.title
  end

  def description
    ""
  end

  def description=(text)
    ""
  end

  def title=(title)
    ""
  end

  def save
  end

  def album_items
    @items
  end
  
  def current_index(defau)
    @index
  end

  def current(defau)
    @current || (@videos.length ? @videos.first : defau)
  end

  def owned_by(_user)
    false
  end

  def transfer_to(user)
  end

  def add_item(video)
  end

  def toggle(_video)
    false
  end

  def all_items(filter)
    @items
  end

  def fetch_items
    @filter.videos
      .must(@filter.build_params(@query).to_hash)
      .where(hidden: false, duplicate_id: 0, listing: 0)
      .order(:created_at)
      .offset(@offset)
      .limit(@index + 5)
      .records
  end

  def add_item(_video)
    item = AlbumItem.new
    @videos << item
  end

  def next_video(filter, current)
    current -= @offset
    return nil if @items.empty? || current >= @items.length - 1
    @items[current + 1]
  end

  def previous_video(filter, current)
    current -= @offset
    return nil if @items.empty? || current < 1
    @items[(current - 1) % @items.length]
  end

  def virtual?
    true
  end
end
