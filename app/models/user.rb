require 'elasticsearch/model'

class UserDummy
  include Roleable
  include Queues

  def initialize(id)
    @id = id
    if id
      @username = 'Background Pony #' + id.to_s(36)
    else
      @username = 'Anonymous'
    end
  end

  def videos
    Video.where(user_id: @id)
  end

  attr_reader :id

  def html_bio
    ''
  end

  attr_reader :username

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
    @user.watched
  end

  def drop_tags(ids)
    TagSubscription.where('user_id = ? AND tag_id IN (?)', @user.id, ids).delete_all
  end

  def pick_up_tags(ids)
  end

  def tags_changed
    @user.update_index(defer: false)
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
         authentication_keys: [:login]
  include Roleable
  include Queues

  include Elasticsearch::Model
  include Indexable
  include Uncachable

  prefs :preferences, subscribe_on_reply: true, subscribe_on_thread: true, subscribe_on_upload: true

  after_destroy :remove_assets
  after_create :init_name

  has_many :votes, dependent: :destroy
  has_many :notifications, dependent: :destroy
  has_many :thread_subscriptions, dependent: :destroy

  belongs_to :album, foreign_key: "star_id"
  has_many :album_items, through: :album

  has_many :videos
  has_many :all_albums, class_name: "Album", foreign_key: "user_id", dependent: :destroy
  has_many :artist_genres, dependent: :destroy
  has_many :tags, through: :artist_genres
  has_many :tag_subscriptions, dependent: :destroy

  has_many :hidden_tags, -> { where(hide: true) }, class_name: "TagSubscription"
  has_many :spoilered_tags, -> { where(spoiler: true) }, class_name: "TagSubscription"
  has_many :watched_tags, -> { where(watch: true, hide: false) }, class_name: "TagSubscription"

  has_many :hidden_tags_actual, through: :hidden_tags, class_name: "Tag", source: "tag"
  has_many :spoilered_tags_actual, through: :spoilered_tags, class_name: "Tag", source: "tag"
  has_many :watched_tags_actual, through: :watched_tags, class_name: "Tag", source: "tag"

  has_many :user_badges
  has_many :badges, through: :user_badges
  belongs_to :tag

  validates :username, presence: true, uniqueness: {
    case_sensitive: false
  }
  validates :username, format: { with: /^[a-zA-Z0-9_\. ]*$/, multiline: true }
  SANITIZE = /[^a-zA-Z0-9]+/
  BP_PONY = /^background pony #([0-9a-z]+)/

  settings index: { number_of_shards: 1 } do
    mappings dynamic: 'true' do
      indexes :username
      indexes :created_at, type: 'date'
      indexes :updated_at, type: 'date'
    end
    mappings dynamic: 'false' do
      indexes :tags, type: 'keyword'
    end
  end

  def as_indexed_json(_options = {})
    json = as_json(only: %w[username created_at updated_at])
    json["tags"] = self.tags.pluck(:name)
    json
  end

  def self.find_for_database_authentication(warden_conditions)
    conditions = warden_conditions.dup
    if login = conditions.delete(:login)
      where(conditions.to_hash).where(['lower(username) = :value OR lower(email) = :value', { value: login.downcase }]).first
    else
      conditions[:email].downcase! if conditions[:email]
      where(conditions.to_hash).first
    end
  end

  attr_writer :login

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
    return false if !(name.present? && !name.strip.empty?)
    !name.gsub(SANITIZE, '').empty?
  end

  def self.with_badges
    includes(user_badges: [:badge])
  end

  def self.dummy(id)
    UserDummy.new(id)
  end

  def self.verify_integrity
    result = [0, 0]
    User.all.find_each do |u|
      if File.exist?(Rails.root.join('public', 'avatar', u.id.to_s))
        if !u.mime
          u.mime = 'png'
          u.save
          result[0] += 1
        end
      else
        if u.mime
          u.mime = nil
          u.save
          result[0] += 1
        end
      end
      if File.exist?(Rails.root.join('public', 'banner', u.id.to_s + '.png'))
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
    result
  end

  def self.by_name_or_id(id)
    User.where('id = ? OR username = ?', id, id).first
  end

  def self.tag_for(user)
    return user.tag if user.tag_id
    if !(tag = Tag.where(short_name: user.username, tag_type_id: 1).first)
      tag = Tag.create(tag_type_id: 1).set_name(user.username)
    end
    tag
  end

  def albums
    self.all_albums.where(hidden: false)
  end

  def drop_tags(ids)
    Tag.where('id IN (?) AND user_count > 0', ids).update_all('user_count = user_count - 1')
    ArtistGenre.where('user_id = ? AND tag_id IN (?)', self.id, ids).delete_all
  end

  def pick_up_tags(ids)
    Tag.where('id IN (?)', ids).update_all('user_count = user_count + 1')
    self.artist_genres
  end

  def tags_changed
    self.update_index(defer: false)
  end

  def removeSelf
    self.all_albums.each(&:removeSelf)
    self.destroy
  end

  def tag_string
    Tag.tag_string(self.tags)
  end

  def hidden_tag_string
    Tag.tag_string(self.hidden_tags_actual)
  end

  def spoilered_tag_string
    Tag.tag_string(self.spoilered_tags_actual)
  end

  def watched_tag_string
    Tag.tag_string(self.watched_tags_actual)
  end

  def stars
    if self.album.nil?
      self.album = self.create_album(
        user_id: self.id,
        title: 'Starred Videos',
        safe_title: 'Starred-Videos',
        description: 'My Favourites',
        hidden: true
      )
      self.save
    end
    self.album
  end

  def taglist
    return "Admin" if self.is_admin
    "User"
  end

  def hides(tags)
    @hidden_tag_ids ||= self.hidden_tags_actual.pluck(:id, :alias_id).map do |t|
      t[1] || t[0]
    end
    !(tags & @hidden_tag_ids).empty?
  end

  def spoilers(tags)
    @spoilered_tag_ids ||= self.spoilered_tags_actual.pluck(:id, :alias_id).map do |t|
      t[1] || t[0]
    end
    !(tags & @spoilered_tag_ids).empty?
  end

  def watches(tag)
    @watched_tag_ids ||= self.watched_tags_actual.pluck(:id, :alias_id).map do |t|
      t[1] || t[0]
    end
    !([tag.id] & @watched_tag_ids).empty?
  end

  def setTags(tags)
    Tag.loadTags(tags, self) if tags
  end

  def setAvatar(avatar)
    self.uncache
    delFile(avatar_path.to_s + '-small' + self.mime.to_s)
    delFile(avatar_path.to_s + self.mime.to_s)
    if avatar && avatar.content_type.include?('image/')
      ext = File.extname(avatar.original_filename)
      ext = Mimes.ext(avatar.content_type) if ext == ''
      if img(avatar_path.to_s + ext, avatar)
        self.mime = ext
        Ffmpeg.crop_avatar(avatar_path.to_s + self.mime, avatar_path.to_s + self.mime)
        Ffmpeg.scale(avatar_path.to_s + self.mime, avatar_path.to_s + '-small' + self.mime, 30)
        # normal: 240
        # small: 30
      else
        self.mime = nil
      end
    else
      self.mime = nil
    end
  end

  def setBanner(banner)
    self.uncache
    if !banner || banner.content_type.include?('image/')
      delFile(banner_path.to_s + '.png')
      self.banner_set = img(banner_path.to_s + '.png', banner)
    end
  end

  def set_name(name)
    name = 'Background Pony #' + self.id.to_s(32) if !self.validate_name(name)
    name = ApplicationHelper.check_and_trunk(name, self.username)
    self.username = name
    self.safe_name = ApplicationHelper.url_safe(name)
    self.save
    self.update_index(defer: false)
  end

  def set_description(text)
    test = ApplicationHelper.demotify(text)
    self.description = text
    self.html_description = ApplicationHelper.emotify(text)
    self
  end

  def set_bio(text)
    test = ApplicationHelper.demotify(text)
    self.bio = text
    self.html_bio = ApplicationHelper.emotify(text)
    self
  end

  def avatar_path
    Rails.root.join('public', 'avatar', self.id.to_s)
  end

  def banner_path
    Rails.root.join('public', 'banner', self.id.to_s)
  end

  def avatar
    if !self.mime
      return Gravatar.avatar_for(self.email, s: 240, d: 'http://www.projectvinyl.net/images/default-avatar.png', r: 'pg')
    end
    self.cache_bust('/avatar/' + self.id.to_s + self.mime)
  end

  def small_avatar
    if !self.mime
      return Gravatar.avatar_for(self.email, s: 30, d: 'http://www.projectvinyl.net/images/default-avatar.png', r: 'pg')
    end
    self.cache_bust('/avatar/' + self.id.to_s + '-small' + self.mime)
  end

  def banner
    self.cache_bust('/banner/' + self.id.to_s + '.png')
  end

  def link
    '/profile/' + self.id.to_s + '-' + (self.safe_name || ('Background Pony #' + self.id.to_s(32)))
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
    @message_count || (@message_count = Pm.where('state = 0 AND unread = true AND user_id = ?', self.id).count)
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
    delFile(banner_path.to_s + '.png')
    delFile(avatar_path.to_s + self.mime.to_s)
    delFile(avatar_path.to_s + '-small' + self.mime.to_s)
  end

  def init_name
    self.set_name(self.username)
  end

  def delFile(path)
    File.delete(path) if File.exist?(path)
  end

  private

  def renameFile(from, to)
    File.rename(from, to) if File.exist?(from)
  end

  def img(path, uploaded_io)
    if uploaded_io
      File.open(path, 'wb') do |file|
        file.write(uploaded_io.read)
        return true
      end
    end
    false
  end
end
