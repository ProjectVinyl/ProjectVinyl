require 'elasticsearch/model'

class Tag < ApplicationRecord
  include Elasticsearch::Model
  include Indexable

  belongs_to :tag_type
  belongs_to :alias, class_name: "Tag", foreign_key: "alias_id"

  has_one :user

  has_many :video_genres, counter_cache: "video_count"
  has_many :videos, through: :video_genres
  has_many :artist_genres, counter_cache: "user_count"
  has_many :users, through: :artist_genres

  has_many :tag_implications, dependent: :destroy
  has_many :implications, through: :tag_implications, foreign_key: "implied_id"

  has_many :tag_histories

  has_many :implying_tags, class_name: "TagImplication", foreign_key: "implied_id"
  has_many :implicators, through: :implying_tags, foreign_key: "tag_id"
  has_many :aliases, class_name: "Tag", foreign_key: "alias_id"

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

  scope :pluck_actual_ids, -> { (pluck(:id, :alias_id).map {|t| t[1] || t[0] }).uniq }
  scope :jsons, ->(sender=nil) { actualise.uniq.map {|t| t.to_json(sender)} }
  scope :split_to_ids, ->(tag_string) {
    names = Tag.split_tag_string(tag_string)
    return [] if names.blank?
    where('name IN (?)', names.uniq).pluck_actual_ids
  }

  scope :actualise, -> { includes(:alias).map(&:actual).uniq }
  scope :actual_names, -> { actualise.map(&:name).uniq }
  scope :by_tag_string, ->(tag_string) {
    names = Tag.split_tag_string(tag_string)
    where('name IN (?) OR short_name IN (?)', names, names)
  }
  scope :by_names, ->(names) {
    return [] if names.nil? || (names = names.uniq).empty?
    where('name IN (?) OR short_name IN (?)', names, names).actualise
  }
  scope :by_name_or_id, ->(name) {
    return none if name.blank?
    order(:video_count, :user_count)
        .reverse_order
        .where('name = ? OR id::text = ? OR short_name = ?', name, name, name)
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

    set_name(name)
    "/tags/#{name}"
  end

  def set_name(name)
    name = Tag.sanitize_name(name)

    if has_type
      name = name.sub(tag_type.prefix + ':', '').delete(':')
      name = tag_type.prefix + ":" + name if !tag_type.hidden
    else
      name = name.delete(':')
    end

    return false if Tag.where('name = ? AND NOT id = ?', name, id).count > 0

    self.short_name = PathHelper.url_safe_for_tags(name)
    self.name = name
    __reindex!
  end

  def set_alias(tag)
    tag_o = tag.actual
    tag = tag_o.id

    if tag && tag != id
      self.alias_id = tag

      Tag.where(alias_id: id).update_all(alias_id: tag)
      User.where(tag_id: id).update_all(tag_id: tag)
      ArtistGenre.where(o_tag_id: id).update_all(tag_id: tag)
      VideoGenre.where(o_tag_id: id).update_all(tag_id: tag)

      self.video_count = self.user_count = 0
      tag_o.__reindex!
      __reindex!
    end
  end

  def unset_alias
    return if !alias_id

    ArtistGenre.where(o_tag_id: id).update_all('tag_id = o_tag_id')
    VideoGenre.where(o_tag_id: id).update_all('tag_id = o_tag_id')
    self.alias_id = nil
    __reindex!
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

    answer = [sender.watches?(self.id) ? '-' : '+']
    answer << 'H' if sender.hides?(id)
    answer << 'S' if sender.spoilers?(id)
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

        tag.set_name(name)
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

  # protected
  # We don't use Tag.create any more because that can create duplicates
  def self.__make(hash)
    sql = 'INSERT INTO tags (' + hash.keys.join(',') + ') VALUES (?) ON CONFLICT (name) DO UPDATE SET name = excluded.name;'
    sql = Tag.send :sanitize_sql_for_conditions, [sql, hash.values]
    ApplicationRecord.connection.execute(sql)
    where(name: hash[:name]).first
  end

  private
  def __recount!
    self.video_count = video_genres.count
    self.user_count = artist_genres.count
  end

  def __reindex!
    __recount!

    save
    videos.each {|v| v.update_index(defer: false) }
    users.each {|u| u.update_index(defer: false) }
    update_index
    self
  end
end
