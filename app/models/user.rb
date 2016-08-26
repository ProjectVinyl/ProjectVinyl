class UserDummy
  def initialize(id)
    @id = id
    @username = 'Background Pony #' + id.to_s(36)
  end
  
  def id
    return @id
  end
  
  def html_bio
    return ''
  end
  
  def username
    return @username
  end
  
  def queue(excluded)
    @queue = Video.randomVideos(Video.where(hidden: false, user_id: @id).where.not(id: excluded), 7)
  end
  
  def avatar
    return '/images/default-avatar.png'
  end
  
  def link
    return ''
  end
  
  def isDummy
    return true
  end
end
class User < ActiveRecord::Base
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable
  
  after_destroy :remove_assets
  
  has_many :votes, dependent: :destroy
  has_many :notifications, dependent: :destroy
  
  belongs_to :album, foreign_key: "star_id"
  has_many :album_items, :through => :album
  
  has_many :videos
  has_many :all_albums, class_name: "Album", foreign_key: "user_id", dependent: :destroy
  has_many :artist_genres, dependent: :destroy
  has_many :tags, :through => :artist_genres
  belongs_to :tag
  
  SANITIZE = /[^a-zA-Z0-9]+/
  BP_PONY = /^background pony #([0-9a-z]+)/
  
  def validate_name(name)
    if (match = User.where('username = ? OR safe_name = ?', name, name).first) && match.id != self.id
      return false
    end
    if bp_id = name.downcase.match(BP_PONY) && bp_id != self.id.to_s(36)
      return false
    end
    if !(name && name.length > 0 && name.strip.length > 0)
      return false
    end
    return name.gsub(SANITIZE, '').length > 0
  end
  
  def self.dummy(id)
    return UserDummy.new(id)
  end
  
  def self.verify_integrity
    result = [0,0]
    User.all.find_in_batches do |o|
      o.each do |u|
        if u.mime && !File.exists?(Rails.root.join('public', 'avatar', u.id.to_s))
          puts u.avatar
          u.setAvatar(false)
          u.save
          result[0] += 1
        end
        if u.banner_set && !File.exists?(Rails.root.join('public', 'banner', u.id.to_s))
          u.setBanner(false)
          u.save
          result[1] += 1
        end
      end
    end
    return result
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
  
  def albums
    return self.all_albums.where(hidden: false)
  end
  
  def queue(excluded)
    return Video.randomVideos(self.videos.where(hidden: false).where.not(id: excluded), 7)
  end
    
  def drop_tags(ids)
    Tag.where('id IN (?) AND user_count > 0', ids).update_all('user_count = user_count - 1')
    ArtistGenre.where('user_id = ? AND tag_id IN (?)', self.id, ids).delete_all
  end
  
  def pick_up_tags(ids)
    Tag.where('id IN (?)', ids).update_all('user_count = user_count + 1')
    return self.artist_genres
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
    if !self.validate_name(name)
      name = 'Background Pony #' + self.id.to_s(32)
    end
    name = ApplicationHelper.check_and_trunk(name, self.username)
    self.username = name
    self.safe_name = ApplicationHelper.url_safe(name)
    self.save
    if self.tag
        self.tag.set_name(name)
    end
  end
  
  def set_description(text)
    test = ApplicationHelper.demotify(text)
    self.description = text
    self.html_description = ApplicationHelper.emotify(text)
    return self
  end
  
  def set_bio(text)
    test = ApplicationHelper.demotify(text)
    self.bio = text
    self.html_bio = ApplicationHelper.emotify(text)
    return self
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
  
  def isDummy
    return false
  end
  
  def send_notification(message, source)
    self.notifications.create(message: message, source: source)
    self.notification_count = self.notification_count + 1
    self.save
  end
  
  protected
  def remove_assets
    img('avatar', false)
    img('banner', false)
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
