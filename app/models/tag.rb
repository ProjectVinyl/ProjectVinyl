class Tag < ActiveRecord::Base
  belongs_to :tag_type
  
  has_one :user
  
  has_many :video_genres
  has_many :videos, :through => :video_genres
  has_many :artist_genres
  has_many :users, :through => :artist_genres
  
  has_many :tag_implications, dependent: :destroy
  has_many :implications, :through => :tag_implications, foreign_key: "implied_id"
  
  has_many :implying_tags, class_name: "TagImplication", foreign_key: "implied_id"
  has_many :implicators, :through => :implying_tags, foreign_key: "tag_id"
  
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
    return tag_string.downcase.split(/,|;/).uniq
  end
  
  def self.get_tag_ids(names)
    if !names || names.length == 0
      return []
    end
    return Tag.where('name IN (?)', names.uniq).pluck(:id).uniq
  end
  
  def self.get_tag_ids_with_create(names)
    if !names || names.length == 0
      return []
    end
    result = []
    existing_names = []
    Tag.where('name IN (?)', names).each do |tag|
      result << tag.id
      existing_names << tag.name
    end
    new_tags = names - existing_names
    new_tags.each do |name|
      name = name.strip
      if name.index('uploader:') != 0 && name.index('title:') != 0
        tag = Tag.create(description: '', tag_type_id: 0)
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
    return result
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
    existing_ids = sender.tags.pluck(:id).uniq
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
    sender.save
  end
  
  def members
    return self.video_count + self.user_count
  end
  
  def get_as_string
    return self.name
  end
  
  def has_type
    return self.tag_type_id & self.tag_type_id > 0
  end
  
  def namespace
    if self.name.index(':')
      return self.name.split(':')[0]
    end
  end
  
  def set_name(name)
    name = name.downcase.strip.gsub(/[;,]/,'')
    if self.has_type
      name = self.tag_type.prefix + ":" + name.gsub(/:/, '')
    end
    self.short_name = ApplicationHelper.url_safe_for_tags(name)
    self.name = name
    self.save
    return self
  end
end
