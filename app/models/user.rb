require 'elasticsearch/model'

class User < ApplicationRecord
  include Elasticsearch::Model
  include Roleable, Queues, Activitied, Indexable, Uncachable,
          Taggable, WithFiles, Tinted, TagSubscribeable

  # Include default devise modules. Others available are:
  # :omniauth_providers, :omniauthable, :lockable and :timeoutable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable, :confirmable,
         authentication_keys: [:login]
  prefs :preferences, subscribe_on_reply: true, subscribe_on_thread: true, subscribe_on_upload: true

  before_validation :init_name
  after_save :update_index, if: :saved_change_to_username?
  after_create :seed_profile

  has_many :comments
  has_many :votes
  has_many :videos
  has_many :tag_histories

  belongs_to :site_filter

  has_many :watch_histories, -> { order(:updated_at, :created_at) }, dependent: :destroy
  has_many :watched_videos, through: :watch_histories, source: :video, class_name: "Video"

  has_many :notification_receivers, dependent: :destroy
  has_many :notifications, dependent: :destroy
  has_many :thread_subscriptions, dependent: :destroy
  has_many :site_filters, dependent: :destroy
  has_many :pms, dependent: :destroy
  has_many :profile_modules, dependent: :destroy

  has_many :unread_notifications, ->{ where(unread: true) }, class_name: "Notification"
  has_many :unread_pms, ->{ where(state: 0, unread: true) }, class_name: "Pm"

  has_many :all_albums, class_name: "Album", foreign_key: "user_id", dependent: :destroy

  has_many :user_badges
  has_many :badges, through: :user_badges

  has_many :artist_genres, dependent: :destroy
  has_many :tags, through: :artist_genres

  has_many :api_tokens, dependent: :destroy
  has_many :tag_subscriptions, dependent: :destroy

  has_many :watched_tags, through: :tag_subscriptions, class_name: "Tag", source: "tag"

  belongs_to :album, foreign_key: "star_id"
  has_many :album_items, through: :album
  belongs_to :tag

  tag_relation :artist_genres

  asset_root :avatar
  has_asset :avatar, :avatar_file_name, group: :avatar do grab_avatar(avatar_url, 240) end
  has_asset :small_avatar, :avatar_file_name, group: :avatar do grab_avatar(small_avatar_url, 30) end
  has_asset :banner, 'banner.png', cache_bust: true

  scope :by_name_or_id, ->(id) { where('id::text = ? OR username = ?', id, id).first }
  scope :with_badges, -> { includes(user_badges: [:badge]) }
  scope :find_matching_users, ->(term) { where('username LIKE ?', "#{term}%").order(:username).limit(10).map(&:to_json) }
  scope :get_as_recipients, ->(users_string) { where('username IN (?)', users_string.split(',').map {|a| a.strip}.uniq) }

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
      indexes :username, type: 'keyword'
      indexes :created_at, type: 'date'
      indexes :updated_at, type: 'date'
      indexes :tags, type: 'keyword'
    end
  end

  def as_indexed_json(_options = {})
    json = as_json(only: %w[created_at updated_at])
    json["username"] = username.downcase
    json["tags"] = tags.pluck(:name)
    json
  end

  def to_json
    {
      name: username,
      namespace: 'users',
      link: link,
      slug: username
    }
  end

  def self.find_for_mention(match)
    User.where('LOWER(username) = ? OR LOWER(safe_name) IN (?)', match, [match, match.underscore].map{|a| PathHelper.url_safe(a) }).first
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
    @login || username || email
  end

  def active_for_authentication?
    super && !banned?
  end

  def inactive_message
    banned? ? "You are banned." : super
  end

  def validate_name(name)
    return false if (match = User.where('username = ? OR safe_name = ?', name, name).first) && match.id != id
    return false if bp_id = name.downcase.match(BP_PONY) && bp_id != id.to_s(36)
    return false if !(name.present? && !name.strip.empty?)

    !name.gsub(SANITIZE, '').empty?
  end

  def self.dummy(id)
    UserDummy.new(id)
  end

  def albums
    all_albums.where(hidden: false)
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

  def avatar=(avatar)
    self.uncache
    remove_avatar
    self.mime = nil

    if avatar
      ext = File.extname(avatar.original_filename)
      ext = Mimes.ext(avatar.content_type) if ext == ''
      self.mime = ext

      if save_file(avatar_path, avatar, 'image/')
        Ffmpeg.crop_avatar(avatar_path, avatar_path)      # normal: 240
        Ffmpeg.scale(avatar_path, small_avatar_path, 30)  # small: 30
      else
        self.mime = nil
      end
    end
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

  def dummy?
    false
  end

  private
  def seed_profile
    ProfileModule.seed(self)
  end

  def default_name
    "Background Pony ##{id.to_s(32)}"
  end

  def init_name
    self.username = StringsHelper.check_and_trunk(username, username_was)
    self.username = username_was if !validate_name(username)
    self.safe_name = PathHelper.url_safe(self.username)
  end

  def avatar_file_name(key)
    key = 'thumb' if key == :small_avatar
    "#{key}#{mime}"
  end

  def grab_avatar(url, size)
    return cache_bust(url) if mime
    Gravatar.avatar_for(email, s: size, d: 'https://www.projectvinyl.net/images/default-avatar.png', r: 'pg')
  end
end
