class Album < ActiveRecord::Base
  belongs_to :user
  has_many :album_items
  has_many :videos, :through => :album_items
  
  def set_description(text)
    test = ApplicationHelper.demotify(text)
    self.description = text
    self.html_description = ApplicationHelper.emotify(text)
    return self
  end
  
  def set_title(title)
    title = ApplicationHelper.check_and_trunk(title, self.title || "Untitled Album")
    self.title = title
    self.safe_title = ApplicationHelper.url_safe(title)
    self.save
  end
  
  def ownedBy(user)
    return user && (self.user_id == user.id || (self.hidden == false && user.is_staff?))
  end
  
  def transferTo(user)
    self.user = user
    self.save
    self.videos.each do |video|
      video.transferTo(user)
    end
  end
  
  def addItem(video)
    index = self.album_items.length
    self.album_items.create(video_id: video.id, index: index, o_video_id: video.id)
    self.repaint_ordering(self.album_items)
  end
  
  def toggle(video)
    if item = self.album_items.where(video_id: video.id).first
      item.removeSelf
      return false
    else
      self.addItem(video)
      return true
    end
  end
  
  def all_items
    @items = @items || self.ordered(self.album_items.includes(:direct_user, video: :tags))
  end
  
  CREATED = 1
  ADDED = 2
  SCORE = 3
  
  def set_ordering(order, direction)
    self.ordering = order.to_i
    self.reverse_ordering = direction == '1'
    self.repaint_ordering(self.album_items)
  end
  
  def ordering_text
    if self.ordering == CREATED
      return "date created"
    elsif self.ordering == SCORE
      return "score"
    elsif self.ordering == ADDED
      return "date added"
    end
    return "custom"
  end
  
  def ordered(items)
    if self.ordering == SCORE
      items = items.joins(:video).order('`videos`.score')
      if self.reverse_ordering
        items = items.reverse_order
      end
      return self.recalculate_ordering(items)
    end
    items = items.order(:index)
    if self.reverse_ordering
      items = items.reverse_order
    end
    return items
  end
  
  def repaint_ordering(items)
    if self.ordering == CREATED
      items = items.joins(:video).order('`videos`.created_at')
    elsif self.ordering == ADDED
      items = items.order(:created_at)
    end
    if self.reverse_ordering
      items = items.reverse_order
    end
    self.recalculate_ordering(items)
  end
  
  def recalculate_ordering(items)
    items.each_with_index do |item,i|
      if item.index != i
        item.index = i
        item.save
      end
    end
    return items
  end
  
  def discriminate(items, comparitor, current)
    return items.where('`album_items`.index ' + comparitor + ' ?', current)
  end
  
  def get_next(user, current)
    potentials = discriminate(self.all_items, '>', current).select do |i|
      !(i.video.isHiddenBy(user) || i.video.hidden)
    end
    return potentials.first
  end
  
  def get_prev(user, current)
    potentials = discriminate(self.all_items, '<', current).select do |i|
      !(i.video.isHiddenBy(user) || i.video.hidden)
    end
    return potentials.last
  end
  
  def virtual?
    false
  end
end