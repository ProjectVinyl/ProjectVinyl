require 'elasticsearch/model'

class Tag < ApplicationRecord
  include Indexable, Upsert

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

  scope :pluck_actual_ids, -> { ( pluck(:id, :alias_id).map {|t| t[1] || t[0] }).uniq }
  scope :jsons, ->(sender=nil) { actualise.uniq.map {|t| t.to_json(sender)} }
  scope :split_to_ids, ->(tag_string) {
    names = Tag.split_tag_string(tag_string)
    return [] if names.blank?
    where(name: names.uniq).pluck_actual_ids
  }
  scope :by_tag_string, ->(tag_string) {
    names = Tag.split_tag_string(tag_string)
    where(name: names).or(where(short_name: names))
  }
  scope :by_names, ->(names) {
    return [] if names.nil? || (names = names.uniq).empty?
    where(name: names).or(where(short_name: names)).actualise
  }

  scope :to_tag_string, -> { pluck(:name).uniq.join(',') }
  scope :actualise, -> { includes(:alias).map(&:actual).uniq }
  scope :actual_names, -> { actualise.map(&:name).uniq }

  scope :by_name_or_id, ->(name) {
    return none if name.blank?
    where(name: name)
      .or(where(short_name: name))
      .or(where('"tags"."id"::text = ?', name))
      .order(:video_count, :user_count)
      .reverse_order
  }
  scope :find_matching_tags, ->(name, sender=nil) {
    name = name.downcase
    includes(:tag_type, :alias)
        .where('"tags"."name" LIKE ? OR "tags"."short_name" LIKE ?', "#{name}%", "#{PathHelper.url_safe_for_tags(name)}%")
        .order(:video_count, :user_count)
        .limit(10)
        .jsons(sender)
  }

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

  def validate_name_and_reindex
    validate_name
    reindex!
  end

  def validate_name
    pair = name_validation(tag_type, name)
    self.name = pair[0]
    self.short_name = pair[1]
  end

  def reindex!
    save
    videos.each &:update_index
    users.each &:update_index
    update_index
    self
  end

  def self.ids_from_string(value)
    create_from_names(split_tag_string(value))
  end

  def self.create_from_names(names)
    return [] if names.blank?

    result = []
    existing_tags = []
    
    Tag.where('name IN (?)', names).find_each do |tag|
      result << (tag.alias_id || tag.id)
      existing_tags << tag
    end

    new_tags = (names - existing_tags.map(&:name))
      .map(&:strip)
      .uniq
      .filter(&Tag.method(:valid_name?))
      .map(&Tag.method(:new_tag_hash))

    new_tags = upsert_all(new_tags, returning: [:id, :tag_type_id], unique_by: [:name])

    TagType.upsert_implications(existing_tags, new_tags, result)

    result.uniq
  end
  
  def self.new_tag_hash(name)
    type = TagType.for_tag_name(name)
    name,short_name = Tag.name_validation(type, name)

    { name: name, short_name: short_name, description: '', tag_type_id: type ? type.id : 0, video_count: 0, user_count: 0 }
  end

  def self.sanitize_name(name)
    StringsHelper.check_and_trunk(name, "").downcase.strip.gsub(/[;,]/, '')
  end

  def self.tag_string(tags)
    tags.map(&:name).uniq.join(',')
  end

  def self.split_tag_string(tag_string)
    return [] if tag_string.blank?
    tag_string.downcase.split(/,|;/).uniq.filter(&Tag.method(:valid_name?))
  end

  def self.valid_name?(tag_name)
    !name.nil? && name.present? && !ProjectVinyl::Search::USER_INDEX_PARAMS.recognises?(tag_name) && !ProjectVinyl::Search::VIDEO_INDEX_PARAMS.recognises?(tag_name)
  end

  def self.name_validation(tag_type, name)
    name = Tag.sanitize_name(name)

    if tag_type
      name = name.sub(tag_type.prefix + ':', '').delete(':')
      name = tag_type.prefix + ":" + name if !tag_type.hidden
    else
      name = name.delete(':')
    end

    [name, PathHelper.url_safe_for_tags(name)]
  end
end
