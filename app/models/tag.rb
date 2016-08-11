class Tag < ActiveRecord::Base
  belongs_to :tag_type
  
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
    Tag.where('name LIKE ?', "%" + name.downcase + "%").limit(10).each do |tag|
      result << { name: tag.name, members: tag.members, colour: tag.get_colour }
    end
    return result
  end
  
  def self.parse_tag_string(tag_string)
    result = []
    if tag_string == ''
      return result
    end
    tag_string = tag_string.downcase.split(/,|;/).uniq
    built = ''
    tag_string.each do |item|
      if tag = Tag.where('name = ?', item).first
        result << tag.id
      end
    end
    return result
  end
  
  def self.parse_tag_string_with_create(tag_string)
    result = []
    if tag_string == ''
      return result
    end
    tag_string = tag_string.downcase.split(/,|;/).uniq
    built = ''
    tag_string.each do |item|
      if item.length > 0 && !(tag = Tag.where('name = ?', item).first)
        if item.index('genre:').nil?
          tag = Tag.create(name: item, description: '', tag_type_id: 0)
          if !item.index(':').nil?
            if type = TagType.where(prefix: item.split(':')[0]).first
              tag.tag_type = type
              tag.save
              result << Tag.load_implications_from_type(tag.id, type)
            end
          end
        end
      end
      if tag
        result << tag.id
      end
    end
    return result
  end
  
  def self.load_implications_from_type(id, type)
    implications = type.type_implications.pluck(:implied_id).uniq
    if implications.length
      items = implications.map do |implied_id|
        { tag_id: id, implied_id: implied_id }
      end
      TagImplication.create(items)
    end
    return implications
  end
  
  def self.expand_implications(tag_ids)
    tag_ids << TagImplication.where('tag_id IN (?)', tag_ids).pluck(:implied_id)
    return tag_ids.uniq
  end
  
  def self.loadTags(tag_string, sender)
    target = sender.preload_tags
    ids = Tag.parse_tag_string_with_create(tag_string)
    ids = Tag.expand_implications(ids)
    entries = ids.map do |id|
      { tag_id: id }
    end
    target.create(entries)
    sender.save
    sender.inc(ids)
  end
  
  def members
    return self.video_count + self.user_count
  end
  
  def has_type
    return self.tag_type_id && self.tag_type_id >= 1
  end
  
  def get_as_string
    return self.name
  end
  
  def get_colour
    if self.has_type
      return self.tag_type.colour
    end
    return ""
  end
  
  def set_name(name)
    self.short_name = name
    name = name.downcase.gsub(/:/, '_').gsub(/[;,]/,'')
    if self.has_type
      name = self.tag_type.prefix + ":" + name
    end
    self.name = name
    self.save
    return self
  end
end
