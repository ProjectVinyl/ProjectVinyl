require 'elasticsearch/model'

class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :omniauth_providers, :omniauthable, :lockable and :timeoutable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable, :confirmable,
         authentication_keys: [:login]
  include Roleable
  include Queues
  include Activitied

  include Elasticsearch::Model
  include Indexable
  include Uncachable
  include Taggable
  include WithFiles
  include Tinted

  prefs :preferences, subscribe_on_reply: true, subscribe_on_thread: true, subscribe_on_upload: true

  after_create :init_name

  has_many :comments
  has_many :votes
  has_many :videos
  has_many :tag_histories

  has_many :watch_histories
  has_many :watched_videos, through: :watch_histories, source: 'video'

  has_many :notification_receivers, dependent: :destroy
  has_many :notifications, dependent: :destroy
  has_many :thread_subscriptions, dependent: :destroy

  has_many :all_albums, class_name: "Album", foreign_key: "user_id", dependent: :destroy

  has_many :user_badges
  has_many :badges, through: :user_badges

  has_many :artist_genres, dependent: :destroy
  has_many :tags, through: :artist_genres

  has_many :api_tokens, dependent: :destroy
  has_many :tag_subscriptions, dependent: :destroy

  has_many :hidden_tags, -> { where(hide: true) }, class_name: "TagSubscription"
  has_many :spoilered_tags, -> { where(spoiler: true) }, class_name: "TagSubscription"
  has_many :watched_tags, -> { where(watch: true, hide: false) }, class_name: "TagSubscription"

  has_many :hidden_tags_actual, through: :hidden_tags, class_name: "Tag", source: "tag"
  has_many :spoilered_tags_actual, through: :spoilered_tags, class_name: "Tag", source: "tag"
  has_many :watched_tags_actual, through: :watched_tags, class_name: "Tag", source: "tag"

  belongs_to :album, foreign_key: "star_id"
  has_many :album_items, through: :album
  belongs_to :tag

  scope :by_name_or_id, ->(id) { where('id::text = ? OR username = ?', id, id).first }

  scope :with_badges, -> { includes(user_badges: [:badge]) }

  validates :username, presence: true, uniqueness: {
    case_sensitive: false
  }
  validates :username, format: {
    with: /^[a-zA-Z0-9_\. ]*$/,
    multiline: true
  }

  SANITIZE = /[^a-zA-Z0-9]+/
  BP_PONY = /^background pony #([0-9a-z]+)/

  document_type 'user'
  settings index: { number_of_shards: 1 } do
    mappings dynamic: 'false' do
      indexes :username, analyzer: 'english', index_options: 'offsets'
      indexes :created_at, type: 'date'
      indexes :updated_at, type: 'date'
      indexes :tags, type: 'keyword'
    end
  end

  def as_indexed_json(_options = {})
    json = as_json(only: %w[username created_at updated_at])
    json["tags"] = tags.pluck(:name)
    json
  end

  def self.find_matching_users(term)
    User.jsons(User.where('username LIKE ?', "#{term}%")
        .order(:username).limit(10))
  end

  def self.get_as_recipients(users_string)
    users_string = users_string.split(',').map {|a| a.strip}

    User.where('username IN (?)', users_string.uniq)
  end

  def self.jsons(users)
    users.map(&:to_json)
  end

  def to_json
    {
      name: username,
      namespace: 'users',
      link: link,
      slug: username
    }
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

  def self.find_for_mention(match)
    match_two = PathHelper.url_safe(match)
    match_four = PathHelper.url_safe(match.underscore)
    where('LOWER(username) = ? OR LOWER(safe_name) = ? OR LOWER(safe_name) = ?', match, match_two, match_four).first
  end

  attr_writer :login

  def login
    @login || username || email
  end

  def active_for_authentication?
    super && !banned?
  end

  def inactive_message
    banned? ? "You are banned." : super
  end

  def validate_name(name)
    if (match = User.where('username = ? OR safe_name = ?', name, name).first) && match.id != id
      return false
    end

    if bp_id = name.downcase.match(BP_PONY) && bp_id != id.to_s(36)
      return false
    end

    return false if !(name.present? && !name.strip.empty?)

    !name.gsub(SANITIZE, '').empty?
  end

  def self.dummy(id)
    UserDummy.new(id)
  end

  def self.tag_for(user)
    return user.tag if user.tag_id
    if !(tag = Tag.where(short_name: user.username, tag_type_id: 1).first)
      tag = Tag.create(tag_type_id: 1).set_name(user.username)
    end
    tag
  end

  def albums
    all_albums.where(hidden: false)
  end

  # Overrides Taggable
  def drop_tags(ids)
    Tag.where('id IN (?) AND user_count > 0', ids).update_all('user_count = user_count - 1')
    ArtistGenre.where('user_id = ? AND tag_id IN (?)', id, ids).delete_all
  end

  def pick_up_tags(ids)
    Tag.where('id IN (?)', ids).update_all('user_count = user_count + 1')
    self.artist_genres
  end
  # ####################

  def hidden_tag_string
    Tag.tag_string(hidden_tags_actual)
  end

  def spoilered_tag_string
    Tag.tag_string(spoilered_tags_actual)
  end

  def watched_tag_string
    Tag.tag_string(watched_tags_actual)
  end

  def stars
    if album.nil?
      self.album = create_album(
        user_id: id,
        title: 'Starred Videos',
        safe_title: 'Starred-Videos',
        description: 'My Favourites',
        hidden: true
      )
      save
    end

    album
  end

  def taglist
    self.is_admin ? "Admin" : "User"
  end

  def hides(tags)
    @hidden_tag_ids ||= hidden_tags_actual.pluck_actual_ids
    !(tags & @hidden_tag_ids).empty?
  end

  def spoilers(tags)
    @spoilered_tag_ids ||= spoilered_tags_actual.pluck_actual_ids
    !(tags & @spoilered_tag_ids).empty?
  end

  def watches(tag)
    @watched_tag_ids ||= watched_tags_actual.pluck_actual_ids
    !([tag.id] & @watched_tag_ids).empty?
  end

  def set_tags(tags)
    Tag.load_tags(tags, self) if tags
  end

  def default_name
    "Background Pony ##{id.to_s(32)}"
  end

  def set_name(name)
    name = default_name if !validate_name(name)
    name = StringsHelper.check_and_trunk(name, username)
    self.username = name
    self.safe_name = PathHelper.url_safe(name)
    self.save
    update_index(defer: false)
  end

  def avatar_path
    file_path("avatar#{mime}")
  end

  def avatar_path_small
    file_path("thumb#{mime}")
  end

  def banner_path
    file_path('banner.png')
  end

  def small_avatar
    grab_avatar(public_url("thumb#{mime}"), 30)
  end

  def avatar
    grab_avatar(public_url("avatar#{mime}"), 240)
  end

  def avatar=(avatar)
    self.uncache
    del_file(avatar_path_small)
    del_file(avatar_path)
    self.mime = nil

    if avatar
      ext = File.extname(avatar.original_filename)
      ext = Mimes.ext(avatar.content_type) if ext == ''
      self.mime = ext

      if save_file(avatar_path, avatar, 'image/')
        Ffmpeg.crop_avatar(avatar_path, avatar_path)      # normal: 240
        Ffmpeg.scale(avatar_path, avatar_path_small, 30)  # small: 30
      else
        self.mime = nil
      end
    end
  end

  def banner
    self.cache_bust(public_url('banner.png'))
  end

  def banner=(banner)
    self.uncache
    self.banner_set = false

    save_file(banner_path, banner, 'image/') do
      self.banner_set = true
    end
  end

  def link
    "/profile/#{id}-#{safe_name || default_name}"
  end

  def is_dummy
    false
  end

  def send_notification(message, source)
    self.notifications.create(message: message, source: source)
    self.notification_count += 1
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

  def model_path
    'avatar'
  end

  def remove_assets
    del_file(banner_path)
    del_file(avatar_path)
    del_file(avatar_path_small)
  end

  def init_name
    set_name(username)
  end

  private
  def grab_avatar(url, size)
    if mime
      return cache_bust(url)
    end
    Gravatar.avatar_for(email, s: size, d: 'https://www.projectvinyl.net/images/default-avatar.png', r: 'pg')
  end
end
