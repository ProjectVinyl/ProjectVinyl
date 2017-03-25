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
  
  def self.sanitize_name(name)
    return ApplicationHelper.check_and_trunk(name, "").downcase.strip.gsub(/[;,]/,'')
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
  
  def self.by_name_or_id(name)
    return !name || name.length == 0 ? [] : Tag.where('name = ? OR id = ? OR short_name = ?', name, name, name)
  end
  
  def self.find_matching_tags(name)
    name = name.downcase
    tags = Tag.includes(:tag_type, :alias).where('name LIKE ? OR short_name LIKE ?', "%" + name + "%", "%" + ApplicationHelper.url_safe_for_tags(name) + "%").limit(10)
    tags = tags.map do |tag|
      tag.alias || tag
    end
    return tags.uniq.map do |tag|
      { name: tag.name, link: tag.short_name, members: tag.members }
    end
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
      t[1] || t[0]
    end
    return result.uniq
  end
  
  def self.get_name_mappings(names)
    if !names || names.length == 0
      return {}
    end
    result = {}
    Tag.where('name IN (?)', names.uniq).pluck(:name, :id, :alias_id).each do |t|
      result[t[0]] = t[2] || t[1]
    end
    return result
  end
  
  def self.get_tag_ids_with_create(names)
    if !names || names.length == 0
      return []
    end
    result = []
    existing_names = []
    Tag.where('name IN (?)', names).each do |tag|
      result << (tag.alias_id || tag.id)
      existing_names << tag.name
    end
    new_tags = names - existing_names
    new_tags.each do |name|
      name = name.strip
      if name && name.length > 0 && name.index('uploader:') != 0 && name.index('title:') != 0
        if !name.index(':').nil?
          type = TagType.where(prefix: name.split(':')[0]).first
        end
        tag = Tag.make(name: name, description: '', tag_type_id: type ? type.id : 0, video_count: 0, user_count: 0)
        if tag.short_name.nil?
          if type
            name = name.sub(name.split(':')[0], '').strip
            result = result | Tag.load_implications_from_type(tag.id, type)
          end
          tag.set_name(name)
        end
        result << tag.id
      end
    end
    return result.uniq
  end
  
  # We don't use Tag.create any more because that can create duplicates
  def self.make(hash)
    values = Tag.hash_to_values(hash)
    sql = 'INSERT INTO tags (' + values[:keys].join(',') + ') VALUES (?) ON DUPLICATE KEY UPDATE name = name;'
    sql = Tag.sanitize_sql([sql, values[:values]])
    ActiveRecord::Base.connection.execute(sql)
    return Tag.where(name: hash[:name]).first
  end
  
  def self.hash_to_values(hash)
    values = []
    keys = hash.map do |key,value|
      values << value
      key
    end
    return {values: values, keys: keys}
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
  
  def self.relation_to_ids(tags)
    return tags.pluck(:id, :alias_id).map do |o|
      (o[1] | o[0])
    end
  end
  
  def self.send_pickup_event(reciever, tags)
    tags = tags.uniq
    map = tags.map do |o|
      {tag_id: o, o_tag_id: o}
    end
    reciever.pick_up_tags(tags).create(map)
  end
  
  def self.addTag(tag_name, sender)
    existing = get_updated_tag_set(sender)
    loaded = Tag.get_tag_ids_with_create([tag_name]) - existing
    if loaded.length > 0
      Tag.load_dif(loaded, [], existing, sender)
    end
  end
  
  def self.loadTags(tag_string, sender)
    existing = get_updated_tag_set(sender)
    loaded = Tag.get_tag_ids_with_create(Tag.split_tag_string(tag_string))
    common = existing & loaded
    if existing.length != loaded.length || existing.length != common.length
      return Tag.load_dif(loaded - common, existing - common, existing, sender)
    end
    return nil
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
    if aliased_from.length > 0
      sender.drop_tags(aliased_from)
      aliased_to = aliased_to - existing
      Tag.send_pickup_event(sender, aliased_to)
    end
    return existing
  end
  
  def self.load_dif(added, removed, existing, sender)
    if added.length > 0
      added = Tag.expand_implications(added)
    end
    if added.length > 0 && removed.length > 0
      removed = removed - added
    end
    if removed.length > 0
      sender.drop_tags(removed)
    end
    if added.length > 0
      added = added - existing
      Tag.send_pickup_event(sender, added)
    end
    sender.tags_changed
    TagSubscription.notify_subscribers(added, removed, existing - removed)
    sender.save
    return [added, removed]
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
    return self.tag_type_id && self.tag_type_id > 0
  end
  
  def namespace
    if self.name.index(':')
      return self.name.split(':')[0]
    end
    return ''
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
    return result + self.id.to_s
  end
  
  def set_name(name)
    name = Tag.sanitize_name(name)
    if self.has_type
      name = self.tag_type.prefix + ":" + name.sub(self.tag_type.prefix + ':', '').gsub(':','')
    else
      name = name.gsub(':','')
    end
    if Tag.where('name = ? AND id != ?', name, self.id).count > 0
      return false
    end
    self.short_name = ApplicationHelper.url_safe_for_tags(name)
    self.name = name
    self.save
    Tag.reindex_for(self.videos, self.users)
    return self
  end
  
  def get_description
    if self.description.nil? || self.description.length == 0
      self.description = "No description Provided"
      self.save
    end
    return self.description
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
    tag_o = tag.alias || tag
    tag = (tag.alias_id || tag.id)
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
    if self.alias_id
      return self.alias.name
    end
    return ""
  end
  
  def recount
    self.video_count = VideoGenre.where(tag_id: self.id).count
    self.user_count = ArtistGenre.where(tag_id: self.id).count
  end
end
