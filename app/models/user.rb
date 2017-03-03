require 'elasticsearch/model'

class UserDummy
  include Roleable
  
  def initialize(id)
    @id = id
    if id
      @username = 'Background Pony #' + id.to_s(36)
    else
      @username = 'Anonymous'
    end
  end
  
  def id
    @id
  end
  
  def html_bio
    ''
  end
  
  def username
    @username
  end
  
  def queue(excluded)
    Video.randomVideos(Video.where(hidden: false, user_id: @id).where.not(id: excluded), 6)
  end
  
  def avatar
    '/images/default-avatar.png'
  end
  
  def link
    ''
  end
  
  def admin?
    self.is_admin?
  end
  
  def contributor?
    false
  end
  
  def role
    -1
  end
  
  def isDummy
    true
  end
end

class Subscription
  def initialize(user)
    @user = user
  end
  
  def tags
    return @user.watched
  end
  
  def drop_tags(ids)
    TagSubscription.where('user_id = ? AND tag_id IN (?)', @user.id, ids).delete_all
  end
  
  def pick_up_tags(ids)
    return @user.tag_subscriptions
  end
  
  def tags_changed
    self.update_index(defer: false)
  end
  
  def save
    @user.save
  end
end

class User < ActiveRecord::Base
  # Include default devise modules. Others available are:
  # :omniauth_providers, :omniauthable, :lockable and :timeoutable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable, :confirmable,
         :authentication_keys => [:login]
  include Roleable
  
  include Elasticsearch::Model
  include Indexable
  
  prefs :preferences, :subscribe_on_reply => true, :subscribe_on_thread => true, :subscribe_on_upload => true, :show_ads => false
  
  after_destroy :remove_assets
  after_create :init_name
  
  has_many :votes, dependent: :destroy
  has_many :notifications, dependent: :destroy
  has_many :thread_subscriptions, dependent: :destroy
  
  belongs_to :album, foreign_key: "star_id"
  has_many :album_items, :through => :album
  
  has_many :videos
  has_many :all_albums, class_name: "Album", foreign_key: "user_id", dependent: :destroy
  has_many :artist_genres, dependent: :destroy
  has_many :tags, :through => :artist_genres
  has_many :tag_subscriptions, dependent: :destroy
  
  has_many :hidden_tags, -> {where(hide: true)}, class_name: "TagSubscription"
  has_many :spoilered_tags, -> {where(spoiler: true)}, class_name: "TagSubscription"
  has_many :watched_tags, -> {where(watch: true, hide: false)}, class_name: "TagSubscription"
  
  has_many :hidden_tags_actual, :through => :hidden_tags, class_name: "Tag", source: "tag"
  has_many :spoilered_tags_actual, :through => :spoilered_tags, class_name: "Tag", source: "tag"
  has_many :watched_tags_actual, :through => :watched_tags, class_name: "Tag", source: "tag"
  
  has_many :user_badges
  has_many :badges, :through => :user_badges
  belongs_to :tag
  
  validates :username, presence: true, uniqueness: {
    case_sensitive: false
  }
  validates_format_of :username, with: /^[a-zA-Z0-9_\.]*$/, multiline: true
  SANITIZE = /[^a-zA-Z0-9]+/
  BP_PONY = /^background pony #([0-9a-z]+)/
  
  settings index: { number_of_shards: 1 } do
    mappings dynamic: 'true' do
      indexes :username
    end
    mappings dynamic: 'false' do
      indexes :tags, type: 'keyword'
    end
  end
  
  def as_indexed_json(options={})
    json = as_json(only: ['username'])
    json["tags"] = self.tags.pluck(:name)
    return json
  end
  
  def self.find_for_database_authentication(warden_conditions)
    conditions = warden_conditions.dup
    if login = conditions.delete(:login)
      where(conditions.to_hash).where(['lower(username) = :value OR lower(email) = :value', {:value => login.downcase}]).first
    else
      conditions[:email].downcase! if conditions[:email]
      where(conditions.to_hash).first
    end
  end
  
  def login=(login)
    @login = login
  end
  
  def login
    @login || self.username || self.email
  end
  
  def active_for_authentication?
    super && !self.banned?
  end
  
  def inactive_message
    self.banned? ? "You are banned." : super
  end
  
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
  
  def self.with_badges
    includes(user_badges: [:badge])
  end
  
  def self.dummy(id)
    return UserDummy.new(id)
  end
  
  def self.verify_integrity
    result = [0,0]
    User.all.find_in_batches do |o|
      o.each do |u|
        if File.exist?(Rails.root.join('public', 'avatar', u.id.to_s))
          if !u.mime
            u.setAvatar(true)
            u.save
            result[0] += 1
          end
        else
          if !u.mime
            u.mime = "image/png"
            u.save
            result[0] += 1
          end
        end
        if File.exist?(Rails.root.join('public', 'banner', u.id.to_s))
          if !u.banner_set
            u.banner_set = true
            u.save
            result[1] += 1
          end
        else
          if u.banner_set
            u.setBanner(false)
            u.save
            result[1] += 1
          end
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
  
  def hidden_tag_string
    return Tag.tag_string(self.hidden_tags_actual)
  end
  
  def spoilered_tag_string
    return Tag.tag_string(self.spoilered_tags_actual)
  end
  
  def watched_tag_string
    return Tag.tag_string(self.watched_tags_actual)
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
  
  def hides(tags)
    @hidden_tag_ids = @hidden_tag_ids || self.hidden_tags_actual.pluck(:id,:alias_id).map do |t|
      t[1] || t[0]
    end
    return (tags & @hidden_tag_ids).length > 0
  end
  
  def spoilers(tags)
    @spoilered_tag_ids = @spoilered_tag_ids || self.spoilered_tags_actual.pluck(:id,:alias_id).map do |t|
      t[1] || t[0]
    end
    return (tags & @spoilered_tag_ids).length > 0
  end
  
  def watches(tag) 
    @watched_tag_ids = @watched_tag_ids || self.watched_tags_actual.pluck(:id,:alias_id).map do |t|
      t[1] || t[0]
    end
    return ([tag.id] & @watched_tag_ids).length > 0
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
    if !self.mime
      return Gravatar.avatar_for(self.email, s: 800, d: 'http://www.projectvinyl.net/images/default-avatar.png', r: 'pg')
    end
    return '/avatar/' + self.id.to_s
  end
  
  def banner
    return '/banner/' + self.id.to_s
  end
  
  def link
    return '/profile/' + self.id.to_s + '-' + (self.safe_name || ('Background Pony #' + self.id.to_s(32)))
  end
  
  def isDummy
    false
  end
  
  def send_notification(message, source)
    self.notifications.create(message: message, source: source)
    self.notification_count = self.notification_count + 1
    self.save
  end
  
  def message_count
    return @message_count || (@message_count = Pm.where('state = 0 AND unread = true AND user_id = ?', self.id).count)
  end
  
  def show_ads?
    option :show_ads
  end
  
  def subscribe_on_reply?
    option :subscribe_on_reply
  end
  
  def subscribe_on_upload?
    option :subscribe_on_upload
  end
  
  def subscribe_on_thread?
    option :subscribe_on_thread
  end
  
  protected
  def remove_assets
    img('avatar', false)
    img('banner', false)
  end
  
  def init_name
    self.set_name(self.username)
  end
  
  private
  def img(type, uploaded_io)
    path = Rails.root.join('public', type, self.id.to_s)
    if File.exist?(path)
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