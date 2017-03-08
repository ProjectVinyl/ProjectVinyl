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
  
  def album
    @album
  end
  
  def video
    @video
  end
  
  def video_id
    @video.id
  end
  
  def album_id
    @album.id
  end
  
  def user
    @album.user
  end
  
  def index
    @index
  end
  
  def ref
    return 'q=' + self.album.query + '&index=' + self.index.to_s
  end
  
  def virtual?
    self.album.virtual?
  end
end

class VirtualAlbum < Album
  def initialize(query, index)
    @index = index < 0 ? 0 : index
    @offset = index < 20 ? 0 : index - 20;
    @query = query.strip
    @items = []
    @videos = []
    if @query && @query.length > 0
      self.fetch_items().each_with_index do |item,i|
        @videos << item
        @items << VirtualAlbumItem.new(self, item, @offset + i)
        if @offset + i == @index
          @current = item
        end
      end
    end
  end
  
  def user
    User.Dummy(0)
  end
  
  def id
    0
  end
  
  def query
    @query
  end
  
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
  def set_description(text)
    return self
  end
  
  def set_title(title)
  end
  
  def save
  end
  
  def album_items
    @items
  end
  
  def videos
    @videos
  end
  
  def current(defau)
    @current || (@videos.length ? @videos.first : defau)
  end
  
  def ownedBy(user)
    return false
  end
  
  def transferTo(user)
  end
  
  def addItem(video)
  end
  
  def toggle(video)
    return false
  end
  
  def all_items
    @items
  end
  
  def fetch_items
    return ProjectVinyl::ElasticSearch::ElasticSelector.new(nil, @query).query(0, @index - @offset + 5).videos.offset(@offset).exec().records()
  end
  
  def addItem(video)
    item = AlbumItem.new
    @videos << item
  end
  
  def get_next(user, current)
    current -= @offset
    if @items.length == 0 || current >= @items.length - 1
      return nil
    end
    return @items[current + 1]
  end
  
  def get_prev(user, current)
    current -= @offset
    if @items.length == 0 || current < 1
      return nil
    end
    return @items[(current - 1) % @items.length]
  end
  
  def virtual?
    true
  end
end