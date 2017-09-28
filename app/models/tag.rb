class Tag < ApplicationRecord
  belongs_to :tag_type
  belongs_to :alias, class_name: "Tag", foreign_key: "alias_id"

  has_one :user

  has_many :video_genres, counter_cache: "video_count"
  has_many :videos, through: :video_genres
  has_many :artist_genres, counter_cache: "user_count"
  has_many :users, through: :artist_genres

  has_many :tag_implications, dependent: :destroy
  has_many :implications, through: :tag_implications, foreign_key: "implied_id"

  has_many :implying_tags, class_name: "TagImplication", foreign_key: "implied_id"
  has_many :implicators, through: :implying_tags, foreign_key: "tag_id"
  has_many :aliases, class_name: "Tag", foreign_key: "alias_id"

  def self.sanitize_sql(arguments)
    Tag.send :sanitize_sql_for_conditions, arguments
  end

  def self.sanitize_name(name)
    ApplicationHelper.check_and_trunk(name, "").downcase.strip.gsub(/[;,]/, '')
  end

  def self.tag_json(tags)
    Tag.actualise(tags).map(&:to_json)
  end
  
  scope :pluck_actual_ids, -> { (pluck(:id, :alias_id).map {|t| t[1] || t[0] }).uniq }
  
	def self.actualise(tags)
		tags.map(&:actual).uniq
	end
	
	def self.jsons(tags)
		Tag.actualise(tags).map(&:to_json)
	end
	
  def actual
    alias_id ? (self.alias || self) : self
  end
  
  def actual_id
    self.alias_id || self.id
  end
  
  def self.tag_string(tags)
    tags.map(&:get_as_string).join(',')
  end
  
  def self.by_name_or_id(name)
    name.blank? ? [] : Tag.order(:video_count, :user_count).reverse_order.where('name = ? OR id = ? OR short_name = ?', name, name, name)
  end

  def self.find_matching_tags(name)
    name = name.downcase
    Tag.jsons(Tag.includes(:tag_type, :alias).where('name LIKE ? OR short_name LIKE ?', "#{name}%", "#{ApplicationHelper.url_safe_for_tags(name)}%")
       .order(:video_count, :user_count).limit(10))
  end

  def self.split_tag_string(tag_string)
    return [] if tag_string.blank?
    tag_string = tag_string.downcase.split(/,|;/).uniq
    tag_string.select do |i|
      i.index('uploader:') != 0 && i.index('title:') != 0
    end
  end

  def self.get_tag_ids(names)
    return [] if names.blank?
    Tag.where('name IN (?)', names.uniq).pluck_actual_ids
  end
  
  def self.get_tags(names)
    if names.nil? || (names = names.uniq).empty?
      return []
    end
    Tag.actualise(Tag.includes(:alias).where('name IN (?) OR short_name IN (?)', names, names))
  end
  
  def self.get_name_mappings(names)
    return {} if names.blank?
    result = {}
    Tag.where('name IN (?)', names.uniq).pluck(:name, :id, :alias_id).each do |t|
      result[t[0]] = t[2] || t[1]
    end
    result
  end

  def self.get_tag_ids_with_create(names)
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
      if !name.index(':').nil?
        type = TagType.where(prefix: name.split(':')[0]).first
      end
      tag = Tag.make(name: name, description: '', tag_type_id: type ? type.id : 0, video_count: 0, user_count: 0)
      if tag.short_name.nil?
        if type
          name = name.sub(name.split(':')[0], '').strip
          result |= Tag.load_implications_from_type(tag.id, type)
        end
        tag.set_name(name)
      end
      result << tag.id
    end
    result.uniq
  end

  # We don't use Tag.create any more because that can create duplicates
  def self.make(hash)
    values = Tag.hash_to_values(hash)
    sql = 'INSERT INTO tags (' + values[:keys].join(',') + ') VALUES (?) ON DUPLICATE KEY UPDATE name = name;'
    sql = Tag.sanitize_sql([sql, values[:values]])
    ApplicationRecord.connection.execute(sql)
    Tag.where(name: hash[:name]).first
  end

  def self.hash_to_values(hash)
    values = []
    keys = hash.map do |key, value|
      values << value
      key
    end
    { values: values, keys: keys }
  end

  def self.load_implications_from_type(id, type)
    implications = type.tag_type_implications.pluck(:implied_id).uniq
    if implications.length
      items = implications.map do |implied_id|
        { tag_id: id, implied_id: implied_id }
      end
      TagImplication.create(items)
    end
    implications
  end

  def self.expand_implications(tag_ids)
    tag_ids | TagImplication.where('tag_id IN (?)', tag_ids).pluck(:implied_id)
  end
  
  def self.relation_to_ids(tags)
    tags.pluck_actual_ids
  end
  
  def self.send_pickup_event(reciever, tags)
    tags = tags.uniq
    reciever = reciever.pick_up_tags(tags)
    if !reciever.nil?
      map = tags.map do |o|
        { tag_id: o, o_tag_id: o }
      end
      reciever.create(map)
    end
  end

  def self.add_tag(tag_name, sender)
    existing = get_updated_tag_set(sender)
    loaded = Tag.get_tag_ids_with_create([tag_name]) - existing
    return Tag.load_dif(loaded, [], existing, sender) if !loaded.empty?
    nil
  end

  def self.load_tags(tag_string, sender)
    existing = get_updated_tag_set(sender)
    loaded = Tag.get_tag_ids_with_create(Tag.split_tag_string(tag_string))
    common = existing & loaded
    if existing.length != loaded.length || existing.length != common.length
      return Tag.load_dif(loaded - common, existing - common, existing, sender)
    end
    nil
  end

  def self.get_updated_tag_set(sender)
    aliased_from = []
    aliased_to = []
    existing = sender.tags.pluck(:id, :alias_id).map do |t|
      if t[1]
        aliased_from << t[0]
        aliased_to << t[1]
      end
      (t[1] || t[0])
    end
    if !aliased_from.empty?
      sender.drop_tags(aliased_from)
      aliased_to -= existing
      Tag.send_pickup_event(sender, aliased_to)
    end
    existing
  end

  def self.load_dif(added, removed, existing, sender)
    added = Tag.expand_implications(added) if !added.empty?
    removed -= added if !added.empty? && !removed.empty?
    sender.drop_tags(removed) if !removed.empty?
    if !added.empty?
      added -= existing
      Tag.send_pickup_event(sender, added)
    end
    sender.tags_changed
    TagSubscription.notify_subscribers(added, removed, existing - removed)
    sender.save
    [added, removed]
  end

  def members
    self.video_count
  end

  def get_as_string
    self.name
  end

  def suffex
    if self.has_type
      prefix = self.tag_type.prefix
      if self.name.index(prefix) == 0
        return self.name.sub(prefix + ":", '')
      end
    end
    self.name
  end

  def tag_string
    Tag.tag_string(self.implications)
  end

  def has_type
    self.tag_type_id && self.tag_type_id > 0
  end

  def namespace
    return self.has_type ? self.tag_type.prefix : ''
  end
	
	def slug
		return self.name.sub(self.namespace + ':', '')
	end
	
  def identifier
    return self.name.split(':')[1] if self.name.index(':')
    self.name
  end

  def link
    result = '/tags/'
    if ApplicationHelper.valid_string?(self.short_name)
      return result + self.short_name
    end
    if ApplicationHelper.valid_string?(self.name)
      self.set_name(self.name)
      return result + self.name
    end
    result + self.id.to_s
  end

  def set_name(name)
    name = Tag.sanitize_name(name)
    if self.has_type
      name = name.sub(self.tag_type.prefix + ':', '').delete(':')
      if !self.tag_type.hidden
        name = self.tag_type.prefix + ":" + name
      end
    else
      name = name.delete(':')
    end
    if Tag.where('name = ? AND NOT id = ?', name, self.id).count > 0
      return false
    end
    self.short_name = ApplicationHelper.url_safe_for_tags(name)
    self.name = name
    self.save
    Tag.reindex_for(self.videos, self.users)
    self
  end

  def get_description
    if self.description.blank?
      return "No description Provided"
    end
    self.description
  end

  def self.reindex_for(videos, users)
    videos.each do |v|
      v.update_index(defer: false)
    end
    users.each do |u|
      u.update_index(defer: false)
    end
  end

  def set_alias(tag)
    tag_o = tag.actual
    tag = tag.actual_id
    if tag && tag != self.id
      self.alias_id = tag
      Tag.where(alias_id: self.id).update_all(alias_id: tag)
      User.where(tag_id: self.id).update_all(tag_id: tag)
      ArtistGenre.where(o_tag_id: self.id).update_all(tag_id: tag)
      VideoGenre.where(o_tag_id: self.id).update_all(tag_id: tag)
      Tag.reindex_for(Video.joins(:video_genres).where('`video_genres`.`o_tag_id` = ?', self.id), User.joins(:artist_genres).where('`artist_genres`.`o_tag_id` = ?', self.id))
      self.video_count = self.user_count = 0
      tag_o.recount
    end
  end

  def unset_alias
    if self.alias_id
      ArtistGenre.where(o_tag_id: self.id).update_all('tag_id = o_tag_id')
      VideoGenre.where(o_tag_id: self.id).update_all('tag_id = o_tag_id')
      self.alias_id = nil
      self.recount
    end
  end

  def alias_tag
    self.alias_id ? self.alias.name : ""
  end

  def recount
    self.video_count = VideoGenre.where(tag_id: self.id).count
    self.user_count = ArtistGenre.where(tag_id: self.id).count
  end

  def to_json
    {
      name: self.get_as_string,
      namespace: self.namespace,
      members: self.members,
      link: self.short_name,
			slug: self.slug
    }
  end
end
