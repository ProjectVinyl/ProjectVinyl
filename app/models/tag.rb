class Tag < ActiveRecord::Base
  belongs_to :tag_type
  belongs_to :alias, class_name: "Tag", foreign_key: "alias_id"
  
  has_one :user
  
  has_many :video_genres, counter_cache: "video_count"
  has_many :videos, :through => :video_genres
  has_many :artist_genres, counter_cache: "user_count"
  has_many :users, :through => :artist_genres
  
  has_many :tag_implications, dependent: :destroy
  has_many :implications, :through => :tag_implications, foreign_key: "implied_id"
  
  has_many :implying_tags, class_name: "TagImplication", foreign_key: "implied_id"
  has_many :implicators, :through => :implying_tags, foreign_key: "tag_id"
  has_many :aliases, class_name: "Tag", foreign_key: "alias_id"
  
  def self.sanitize_sql(arguments)
    return Tag.sanitize_sql_for_conditions(arguments)
  end
  
  def self.tag_string(tags)
    result = ''
    tags.each do |i|
      if result.length > 0
        result = result + ','
      end
      result = result + i.get_as_string
    end
    return result
  end
  
  def self.find_matching_tags(name)
    result = []
    Tag.includes(:tag_type).where('name LIKE ?', "%" + name.downcase + "%").limit(10).each do |tag|
      result << { name: tag.name, link: tag.short_name, members: tag.members }
    end
    return result
  end
  
  def self.split_tag_string(tag_string)
    if !tag_string || tag_string.length == 0
      return []
    end
    tag_string = tag_string.downcase.split(/,|;/).uniq
    return tag_string.select do |i|
      i.index('uploader:') != 0 && i.index('title:') != 0
    end
  end
  
  def self.get_tag_ids(names)
    if !names || names.length == 0
      return []
    end
    result = Tag.where('name IN (?)', names.uniq).pluck(:id, :alias_id).map do |t|
      if t[1]
        yield(t[0])
      end
      t[1] || t[0]
    end
    return result.uniq
  end
  
  def self.get_tag_ids_with_create(names)
    if !names || names.length == 0
      return []
    end
    result = []
    existing_names = []
    Tag.includes(:alias).where('name IN (?)', names).each do |tag|
      if tag.alias_id
        yield(tag.id)
      end
      result << (tag.alias_id || tag.id)
      existing_names << tag.name
    end
    new_tags = names - existing_names
    new_tags.each do |name|
      name = name.strip
      if name.index('uploader:') != 0 && name.index('title:') != 0
        tag = Tag.create(description: '', tag_type_id: 0, video_count: 0, user_count: 0)
        if !name.index(':').nil? && type = TagType.where(prefix: name.split(':')[0]).first
          tag.tag_type = type
          tag.set_name(name.sub(name.split(':')[0], '').strip)
          result = result | Tag.load_implications_from_type(tag.id, type)
        else
          tag.set_name(name)
        end
        result << tag.id
      end
    end
    return result.uniq
  end
  
  def self.load_implications_from_type(id, type)
    implications = type.tag_type_implications.pluck(:implied_id).uniq
    if implications.length
      items = implications.map do |implied_id|
        { tag_id: id, implied_id: implied_id }
      end
      TagImplication.create(items)
    end
    return implications
  end
  
  def self.expand_implications(tag_ids)
    return tag_ids | TagImplication.where('tag_id IN (?)', tag_ids).pluck(:implied_id)
  end
  
  def self.loadTags(tag_string, sender)
    aliased_from = []
    aliased_to = []
    existing_ids = sender.tags.pluck(:id, :alias_id).map do |t|
      if t[1]
        aliased_from << t[0]
        aliased_to << t[1]
      end
      (t[1] || t[0])
    end
    if aliased_from.length > 0
      sender.drop_tags(aliased_from)
      sender.pick_up_tags(aliased_to)
    end
    existing = sender.tags.pluck(:name).uniq
    loaded = Tag.split_tag_string(tag_string)
    common = existing & loaded
    if existing.length != loaded.length || common.length != existing.length
      Tag.load_dif(loaded - common, existing - common, existing_ids, sender)
    end
  end
  
  def self.load_dif(added, removed, existing_ids, sender)
    if added.length > 0
      added = Tag.get_tag_ids_with_create(added)
      added = Tag.expand_implications(added)
    end
    if added.length > 0 && removed.length > 0
      removed = removed - added
    end
    if removed.length > 0
      removed = Tag.get_tag_ids(removed)
      sender.drop_tags(removed)
    end
    if added.length > 0
      added = added - existing_ids
      entries = added.map do |id|
        { tag_id: id }
      end
      sender.pick_up_tags(added).create(entries)
    end
    TagSubscription.notify_subscribers(added, removed, existing_ids - removed)
    sender.save
  end
    
  def members
    return self.video_count + self.user_count
  end
  
  def get_as_string
    return self.name
  end
  
  def suffex
    if self.has_type
      prefix = self.tag_type.prefix
      if self.name.index(prefix) == 0
        return self.name.sub(prefix + ":", '')
      end
    end
    return self.name
  end
  
  def tag_string
    return Tag.tag_string(self.implications)
  end
  
  def has_type
    return self.tag_type_id & self.tag_type_id > 0
  end
  
  def namespace
    if self.name.index(':')
      return self.name.split(':')[0]
    end
    return ''
  end
  
  def set_name(name)
    name = ApplicationHelper.check_and_trunk(name, "")
    name = name.downcase.strip.gsub(/[;,]/,'')
    if self.has_type
      name = self.tag_type.prefix + ":" + name.gsub(/:/, '')
    end
    self.short_name = ApplicationHelper.url_safe_for_tags(name)
    self.name = name
    self.save
    return self
  end
  
  def get_description
    if self.description.nil? || self.description.length == 0
      self.description = "No description Provided"
      self.save
    end
    return self.description
  end
  
  def set_alias(tag)
    tag = (tag.alias_id || tag.id)
    if tag && tag != self.id
      self.alias_id = tag
    end
  end
  
  def alias_tag
    if self.alias_id
      return self.alias.name
    end
    return ""
  end
end
