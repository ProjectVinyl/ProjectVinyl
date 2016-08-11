class User < ActiveRecord::Base
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable
  
  has_many :votes, dependent: :destroy
  has_many :notifications, dependent: :destroy
  
  belongs_to :album, foreign_key: "star_id"
  has_many :album_items, :through => :album
  
  has_many :videos
  has_many :all_albums, class_name: "Album", foreign_key: "user_id"
  has_many :artist_genres, dependent: :destroy
  has_many :tags, :through => :artist_genres
  belongs_to :tag
  
  def albums
    return self.all_albums.where(hidden: false)
  end
  
  def self.by_name_or_id(id)
    return User.where('id = ? OR username = ?', id, id).first
  end
  
  def self.tag_for(user)
    if user.tag_id
      return user.tag
    end
    if !(tag = Tag.where(short_name: user.username, tag_type_id: 1).first)
      tag = Tag.create(tag_type_id: 1).set_name(user.username)
    end
    return tag
  end
  
  def preload_tags
    tags = Tag.joins('INNER JOIN `artist_genres` ON `artist_genres`.tag_id = `tags`.id').where('`artist_genres`.user_id = ? AND `tags`.user_count > 0', self.id)
    tags.update_all('`tags`.user_count = `tags`.user_count - 1')
    ArtistGenre.where(user_id: self.id).delete_all
    return self.artist_genres
  end
  
  def inc(ids)
    Tag.where('id IN (?)', ids).update_all('user_count = user_count + 1')
  end
  
  def removeSelf
    self.all_albums.each do |album|
      album.removeSelf
    end
    self.destroy
  end
  
  def tag_string
    return Tag.tag_string(self.tags)
  end
  
  def stars
    if self.album.nil?
      self.album = self.create_album(
        owner_id: self.id,
        title: 'Starred Videos',
        safe_title: 'Starred-Videos',
        description: 'My Favourites',
        hidden: true)
      self.save
    end
    return self.album
  end
  
  def taglist
    if self.is_admin
      return "Admin"
    end
    return "User"
  end
  
  def setTags(tags)
    if tags
      Tag.loadTags(tags, self)
    end
  end
  
  def setAvatar(avatar)
    if !avatar || avatar.content_type.include?('image/')
      if img('avatar', avatar)
        self.mime = avatar.content_type
      else
        self.mime = nil
      end
    end
  end
  
  def setBanner(banner)
    if !banner || banner.content_type.include?('image/')
      self.banner_set = img('banner', banner)
    end
  end
  
  def set_name(name)
    if !name || name.length == 0
      name = 'Background Pony #' + self.id.to_s
    end
    self.username = name
    self.safe_name = ApplicationHelper.url_safe(name)
    self.save
    if self.tag
        user.tag.set_name(name)
    end
  end
  
  def avatar
    return '/avatar/' + self.id.to_s
  end
  
  def banner
    return '/banner/' + self.id.to_s
  end
  
  def link
    return '/profile/' + self.id.to_s + '-' + self.safe_name
  end
  
  def send_notification(message, source)
    self.notifications.create(message: message, source: source)
    self.notification_count = self.notification_count + 1
    self.save
  end
  
  private
  def img(type, uploaded_io)
    path = Rails.root.join('public', type, self.id.to_s)
    if File.exists?(path)
      File.delete(path)
    end
    if uploaded_io
      File.open(path, 'wb') do |file|
        file.write(uploaded_io.read)
        return true
      end
    end
    return false
  end
end
