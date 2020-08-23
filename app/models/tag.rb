require 'elasticsearch/model'

class Tag < ApplicationRecord
  include Elasticsearch::Model
  include Indexable

  belongs_to :tag_type
  belongs_to :alias, class_name: "Tag", foreign_key: "alias_id"

  has_one :user

  has_many :video_genres
  has_many :videos, through: :video_genres
  has_many :artist_genres
  has_many :users, through: :artist_genres

  has_many :tag_implications, dependent: :destroy
  has_many :implications, through: :tag_implications, foreign_key: "implied_id"

  has_many :tag_histories

  has_many :implying_tags, class_name: "TagImplication", foreign_key: "implied_id"
  has_many :implicators, through: :implying_tags, foreign_key: "tag_id"
  has_many :aliases, class_name: "Tag", foreign_key: "alias_id"

  validates :name, uniqueness: true, presence: true
  before_validation :validate_name, if: :will_save_change_to_name?

  document_type 'tag'
  settings index: { number_of_shards: 1 } do
    mappings dynamic: 'false' do
      indexes :name, type: 'keyword'
      indexes :slug, type: 'keyword'
      indexes :namespace, type: 'keyword'
      indexes :aliases, type: 'keyword'
      indexes :implicators, type: 'keyword'
      indexes :implications, type: 'keyword'
      indexes :video_count, type: 'integer'
      indexes :user_count, type: 'integer'
      indexes :created_at, type: 'date'
      indexes :updated_at, type: 'date'
    end
  end

  def as_indexed_json(_options = {})
    json = as_json(only: %w[name slug namespace video_count user_count])
    json['slug'] = slug
    json['namespace'] = namespace
    json['aliases'] = aliases.pluck(:name)
    json['implicators'] = implicators.pluck(:name)
    json['implications'] = implications.pluck(:name)
    json
  end

  scope :pluck_actual_ids, -> { ( pluck(:id, :alias_id).map {|t| t[1] || t[0] }).uniq }
  scope :jsons, ->(sender=nil) { actualise.uniq.map {|t| t.to_json(sender)} }
  scope :split_to_ids, ->(tag_string) {
    names = Tag.split_tag_string(tag_string)
    return [] if names.blank?
    where('"tags"."name" IN (?)', names.uniq).pluck_actual_ids
  }
  scope :by_tag_string, ->(tag_string) {
    names = Tag.split_tag_string(tag_string)
    where('"tags"."name" IN (?) OR "tags"."short_name" IN (?)', names, names)
  }

  scope :actualise, -> { includes(:alias).map(&:actual).uniq }
  scope :actual_names, -> { actualise.map(&:name).uniq }

  scope :by_names, ->(names) {
    return [] if names.nil? || (names = names.uniq).empty?
    where('"tags"."name" IN (?) OR "tags"."short_name" IN (?)', names, names).actualise
  }
  scope :by_name_or_id, ->(name) {
    return none if name.blank?
    order(:video_count, :user_count)
        .reverse_order
        .where('"tags"."name" = ? OR "tags"."id"::text = ? OR "tags"."short_name" = ?', name, name, name)
  }
  scope :find_matching_tags, ->(name, sender=nil) {
    name = name.downcase
    includes(:tag_type, :alias)
        .where('"tags"."name" LIKE ? OR "tags"."short_name" LIKE ?', "#{name}%", "#{PathHelper.url_safe_for_tags(name)}%")
        .order(:video_count, :user_count)
        .limit(10)
        .jsons(sender)
  }

  def actual
    alias_id ? (self.alias || self) : self
  end

  # The total number of entities carrying this tag.
  # Only videos for now.
  def members
    video_count
  end

  def tag_string
    Tag.tag_string(implications)
  end

  def has_type
    tag_type_id && tag_type_id > 0
  end

  # Namespace inherited from the tag's type if present
  def namespace
    has_type ? tag_type.prefix : ''
  end

  # Name without namespace
  def slug
    name.sub(namespace + ':', '')
  end

  # Same as the slug
  def suffex
    slug
  end

  # Last part of the name without the prefix
  def identifier
    name.index(':') ? name.split(':')[1] : name
  end

  # The alias tag name. Required for the forms
  def alias_tag
    self.alias_id && self.alias ? self.alias.name : ""
  end

  def link
    return "/tags/#{short_name}" if StringsHelper.valid_string?(short_name)
    return "/tags/#{id}" if !StringsHelper.valid_string?(name)
    "/tags/#{name}"
  end

  def to_json(sender=nil)
    {
      name: name,
      namespace: namespace,
      members: members,
      link: short_name,
      slug: slug,
      flags: flags(sender)
    }
  end

  def flags(sender=nil)
    return '' if sender.nil?

    answer = [sender.watches?(actual.id) ? '-' : '+']
    answer << 'H' if sender.hides?(actual.id)
    answer << 'S' if sender.spoilers?(actual.id)
    answer.join(' ')
  end

  def self.create_from_names(names)
    return [] if names.blank?
    result = []
    existing_names = []

    Tag.where('name IN (?)', names).find_each do |tag|
      result << (tag.alias_id || tag.id)
      existing_names << tag.name
    end

    new_tags = names - existing_names
    new_tags.each do |name|
      name = name.strip
      next unless name.present? && name.index('uploader:') != 0 && name.index('title:') != 0

      type = TagType.where(prefix: name.split(':')[0]).first if !name.index(':').nil?
      tag = __make(name: name, description: '', tag_type_id: type ? type.id : 0, video_count: 0, user_count: 0)

      if tag.short_name.nil?
        if type
          name = name.sub(name.split(':')[0], '').strip
          result |= type.create_implications! tag
        end

        tag.name = name
        tag.save
      end
      result << tag.id
    end

    result.uniq
  end

  def self.sanitize_name(name)
    StringsHelper.check_and_trunk(name, "").downcase.strip.gsub(/[;,]/, '')
  end

  def self.tag_string(tags)
    tags.map(&:name).uniq.join(',')
  end

  def self.split_tag_string(tag_string)
    return [] if tag_string.blank?
    tag_string.downcase.split(/,|;/).uniq.filter{|i| !Tag.name_illegal?(i) }
  end

  def self.name_illegal?(tag_name)
    ProjectVinyl::Search::USER_INDEX_PARAMS.recognises?(tag_name) || ProjectVinyl::Search::VIDEO_INDEX_PARAMS.recognises?(tag_name)
  end

  def validate_name_and_reindex
    validate_name
    reindex!
  end

  def validate_name
    self.name = Tag.sanitize_name(name)

    if has_type
      self.name = name.sub(tag_type.prefix + ':', '').delete(':')
      self.name = tag_type.prefix + ":" + name if !tag_type.hidden
    else
      self.name = name.delete(':')
    end

    self.short_name = PathHelper.url_safe_for_tags(name)
  end

  # protected
  # We don't use Tag.create any more because that can create duplicates
  def self.__make(hash)
    sql = 'INSERT INTO tags (' + hash.keys.join(',') + ') VALUES (?) ON CONFLICT (name) DO UPDATE SET name = excluded.name;'
    sql = Tag.send :sanitize_sql_for_conditions, [sql, hash.values]
    ApplicationRecord.connection.execute(sql)
    where(name: hash[:name]).first
  end

  def reindex!
    save
    videos.each &:update_index
    users.each &:update_index
    update_index
    self
  end
end
