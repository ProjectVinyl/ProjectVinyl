require 'projectvinyl/elasticsearch/elastic_selector'

class VirtualAlbum < Album
  def initialize(query, id, index)
    @index = index < 0 ? 0 : index
    @offset = @index < 20 ? 0 : @index - 20
    @query = query.strip
    @items = []
    @videos = []
    if @query.present?
      self.fetch_items.each_with_index do |item, i|
        @videos << item
        @items << VirtualAlbumItem.new(self, item, @offset + i)
        
        if item.id == id
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

  attr_reader :query, :videos

  def title
    "Mix - #{@query}"
  end

  def safe_title
    self.title
  end

  def description
    ""
  end

  def html_description
    self.description
  end

  def set_description(_text)
    self
  end

  def set_title(title)
  end

  def save
  end

  def album_items
    @items
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

  def all_items
    @items
  end

  def fetch_items
    ProjectVinyl::ElasticSearch::ElasticSelector.new(nil, @query)
      .order_by(:created_at)
      .query(0, @index - @offset + 5)
      .videos
      .offset(@offset)
      .exec
      .records
  end

  def add_item(_video)
    item = AlbumItem.new
    @videos << item
  end

  def get_next(_user, current)
    current -= @offset
    return nil if @items.empty? || current >= @items.length - 1
    @items[current + 1]
  end

  def get_prev(_user, current)
    current -= @offset
    return nil if @items.empty? || current < 1
    @items[(current - 1) % @items.length]
  end

  def virtual?
    true
  end
end
