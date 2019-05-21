class Album < ApplicationRecord
  belongs_to :user
  has_many :album_items
  has_many :videos, through: :album_items
  
  CREATED = 1
  ADDED = 2
  SCORE = 3
  
  def sample_videos
    self.ordered(self.videos.where(hidden: false).limit(4))
  end
  
  def set_description(text)
    self.description = text
    self.html_description = BbcodeHelper.emotify(text)
    self
  end

  def set_title(title)
    title = StringsHelper.check_and_trunk(title, self.title || "Untitled Album")
    self.title = title
    self.safe_title = PathHelper.url_safe(title)
    self.save
  end

  def owned_by(user)
    user && (self.user_id == user.id || (self.hidden == false && user.is_staff?))
  end

  def transfer_to(user)
    self.user = user
    self.save
    self.videos.each do |video|
      video.transfer_to(user)
    end
  end

  def add_item(video)
    index = self.album_items.length
    self.album_items.create(video_id: video.id, index: index, o_video_id: video.id)
    self.repaint_ordering(self.album_items)
  end

  def toggle(video)
    if item = self.album_items.where(video_id: video.id).first
      item.destroy
      return false
    end
    self.add_item(video)
    true
  end

  def all_items
    @items ||= self.ordered(self.album_items.includes(:direct_user, video: :tags))
  end

  def link
    "/albums/#{self.id}-#{self.safe_title}"
  end
  
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
    "custom"
  end

  def ordering_direction
    self.reverse_ordering ? "desc" : "asc"
  end

  def ordered(items)
    if self.ordering == SCORE
      items = items.joins(:video).order('`videos`.score')
      items = items.reverse_order if self.reverse_ordering
      return self.recalculate_ordering(items)
    end
    items.order('album_items.index')
  end

  def repaint_ordering(items)
    if self.ordering == CREATED
      items = items.joins(:video).order('`videos`.created_at')
    elsif self.ordering == ADDED
      items = items.order(:created_at)
    end
    items = items.reverse_order if self.reverse_ordering
    self.recalculate_ordering(items)
  end

  def recalculate_ordering(items)
    items.each_with_index do |item, i|
      if item.index != i
        item.index = i
        item.save
      end
    end
    items
  end
  
  def current_index(defau)
    defau
  end
  
  def get_next(user, current)
    self.all_items.discriminate('>', current, user).first
  end

  def get_prev(user, current)
    self.all_items.discriminate('<', current, user).last
  end

  def virtual?
    false
  end
end
