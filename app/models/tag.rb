class Tag < ActiveRecord::Base
  belongs_to :tag_type
  
  has_many :video_genres
  has_many :videos, :through => :video_genres
  has_many :artist_genres
  has_many :artists, :through => :artist_genres
  
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
      result << { name: tag.name, members: VideoGenre.where(tag_id: tag.id).length, colour: tag.get_colour }
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
        result << tag
      end
    end
    return result
  end
  
  def self.parse_tag_string_with_create(tag_string)
    result = []
    if tag_string == ''
      return result
    end
    tag_string = tag_string.downcase.split(/,|;/)
    built = ''
    tag_string.each do |item|
      if item.length > 0 && !(tag = Tag.where('name = ?', item).first)
        if item.index('genre:').nil?
          tag = Tag.create(name: item, description: '', tag_type_id: 0)
          if !item.index(':').nil?
            if type = TagType.where(prefix: item.split(':')[0]).first
              tag.tag_type = type
              tag.save
            end
          end
        end
      end
      if tag
        result << tag
      end
    end
    return result
  end
  
  def self.loadTags(tag_string, sender)
    target = sender.preload_tags
    Tag.parse_tag_string_with_create(tag_string).each_with_index do |tag, index|
      target.create(tag_id: tag.id)
    end
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
  
  def total_videos
    return self.videos.uniq.length
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
