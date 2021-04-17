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

  scope :jsons, ->(sender=nil) { actualise.uniq.map {|t| t.to_json(sender)} }

  scope :actual_ids, -> { ( pluck(:id, :alias_id).map {|t| t[1] || t[0] }).uniq }
  scope :split_to_ids, ->(tag_string) {
    names = Tag.split_to_names(tag_string)
    return [] if names.blank?
    where(name: names.uniq).actual_ids
  }
  scope :to_tag_string, -> { pluck(:name).uniq.join(',') }
  scope :actualise, -> { includes(:alias).map(&:actual).uniq }
  scope :actual_names, -> { actualise.map(&:name).uniq }

  scope :by_tag_string, ->(tag_string) {
    names = Tag.split_to_names(tag_string)
    where(name: names).or(where(slug: names))
  }
  scope :by_names, ->(names) {
    return [] if names.nil? || (names = names.uniq).empty?
    where(name: names).or(where(slug: names)).actualise
  }
  scope :by_name_or_id, ->(name) {
    return none if name.blank?
    where(name: name)
      .or(where(slug: name))
      .or(where('"tags"."id"::text = ?', name))
      .ordered
      .reverse_order
  }
  scope :by_name_or_slug, ->(name) {
    return none if name.blank?
    name = name.downcase
    includes(:tag_type, :alias).where('"tags"."name" LIKE ? OR "tags"."slug" LIKE ?', "#{name}%", "#{name.sub(':', '-colon-')}%")
  }
  scope :ordered, -> { order(:name, :video_count, :user_count) }

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

  # Optionally replaces this tag with its downstream alias
  def actual
    alias_id ? (self.alias || self) : self
  end

  # The total number of entities carrying this tag.
  # Only videos for now.
  def members
    video_count
  end

  # The alias tag name. Required for the forms
  def alias_tag
    self.alias_id && self.alias ? self.alias.name : ""
  end

  def link
    return "/tags/#{slug}" if StringsHelper.valid_string?(slug)
    return "/tags/#{id}" if !StringsHelper.valid_string?(name)
    "/tags/#{name}"
  end

  def to_json(sender=nil)
    {
      name: name,
      namespace: namespace,
      members: members,
      slug: slug,
      link: slug,
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
    update(TagType.parse_name(name, tag_type: tag_type)[:tag])
  end

  def reindex!
    save
    videos.each &:update_index
    users.each &:update_index
    update_index
    self
  end

  def self.tag_string(tags)
    tags.map(&:name).uniq.join(',')
  end

  def self.split_to_names(tag_string)
    return [] if tag_string.blank?
    tag_string.downcase.split(/,|;/).uniq.filter(&Tag.method(:valid_name?))
  end

  def self.ids_from_string(value)
    create_from_names(split_to_names(value))
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
      .map do |name|
        TagType.parse_name(name, user_assign: true)[:tag].merge(
          description: '',
          video_count: 0,
          user_count: 0
        )
    end

    new_tags = upsert_all(new_tags, returning: [:id, :tag_type_id], unique_by: [:name])

    TagType.upsert_implications(existing_tags, new_tags, result)

    result.uniq
  end

  def self.sanitize_name(name)
    StringsHelper.check_and_trunk(name, "").downcase.strip.gsub(/[;,]/, '')
  end

  def self.valid_name?(tag_name)
    !name.nil? && name.present? && !ProjectVinyl::Search::USER_INDEX_PARAMS.recognises?(tag_name) && !ProjectVinyl::Search::VIDEO_INDEX_PARAMS.recognises?(tag_name)
  end
end
