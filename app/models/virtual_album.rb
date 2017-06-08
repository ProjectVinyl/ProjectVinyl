require 'projectvinyl/elasticsearch/elastic_selector'

class VirtualAlbumItem < AlbumItem
  def initialize(valbum, video, i)
    @album = valbum
    @video = video
    @index = i
  end

  def id
    0
  end

  attr_reader :album, :video, :index

  def video_id
    @video.id
  end

  def album_id
    @album.id
  end

  def user
    @album.user
  end

  def ref
    'q=' + self.album.query + '&index=' + self.index.to_s
  end

  def virtual?
    self.album.virtual?
  end
end

class VirtualAlbum < Album
  def initialize(query, index)
    @index = index < 0 ? 0 : index
    @offset = index < 20 ? 0 : index - 20
    @query = query.strip
    @items = []
    @videos = []
    if @query.present?
      self.fetch_items.each_with_index do |item, i|
        @videos << item
        @items << VirtualAlbumItem.new(self, item, @offset + i)
        @current = item if @offset + i == @index
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
    "Mix - " + @query
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
    ProjectVinyl::ElasticSearch::ElasticSelector.new(nil, @query).query(0, @index - @offset + 5).videos.offset(@offset).exec.records
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
