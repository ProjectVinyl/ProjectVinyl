class TagType < ApplicationRecord
  include Taggable

  has_many :tag_type_implications, dependent: :destroy
  has_many :tags, through: :tag_type_implications, source: :implied
  has_many :referrers, class_name: "Tag"

  after_destroy :unlink_tags

  def find_and_assign
    Tag.transaction do
      Tag.where('name LIKE ?', prefix + ':%').update_all(tag_type_id: id, namespace: prefix)
      Tag.where(tag_type_id: id).find_each(&:validate_name_and_reindex)
    end
  end

  def drop_tags(ids)
    tag_type_implications.where('implied_id IN (?)', ids).delete_all
  end

  def pick_up_tags(ids)
    TagTypeImplication.create(ids_to_type_imps ids)
    nil
  end

  def self.upsert_implications(existing_tags, new_tags, result)
    new_tag_type_map = {}
    new_tags.each do |tag|
      __push_id(new_tag_type_map, tag["tag_type_id"].to_i, tag["id"].to_i)
      result << id
    end
    existing_tags.each do |tag|
      __push_id(new_tag_type_map, tag.tag_type_id)
    end

    new_mps = []
    new_tag_type_map.each do |id, tag_ids|
      imps = TagTypeImplication.where(tag_type_id: id).unique_tag_ids
      if imps.length
        result += imps
        new_mps += TagType.ids_to_imps(tag_ids, imps)
      end
    end

    TagImplication.upsert_all(new_mps, returning: false, unique_by: [:tag_id, :implied_id])
  end
  
  #
  # artist:sollace
  # prefix=artist
  # suffex=sollace
  # name=artist:sollace
  # slug=artist-colon-collace
  #

  def self.parse_name(name, tag_type: nil, user_assign: false)
    name = Tag.sanitize_name(name)
    prefix, suffex = split_name(name)

    tag_type = TagType.where(prefix: prefix).first if tag_type.nil?

    if tag_type
      prefix = tag_type.prefix
      name = prefix + ':' + suffex
      
      name = remove_prefix(tag_type.prefix, name) if tag_type.hidden
      
      if user_assign && !tag_type.user_assignable
        prefix = ''
        name = name.sub(':', ' ')
        tag_type = nil
      end
    end

    {
      tag_type: tag_type,
      tag: {
        tag_type_id: tag_type ? tag_type.id : 0,
        name: name,
        namespace: prefix,
        suffex: suffex,
        slug: name.sub(':', '-colon-')
      }
    }
  end
  
  def self.split_name(name)
    parts = name.split(':')
    return [ parts[0], remove_prefix(parts[0], name) ] if parts.length > 1
    ['', name]
  end
  
  def self.remove_prefix(prefix, name)
    return name.sub(prefix + ':', '').delete(':') if name.index(prefix + ':') == 0
    name.delete(':')
  end

  private
  def self.__push_id(mapping, type_id, id = nil)
    return if !type_id
    mapping[type_id] = [] if !mapping[type_id]
    mapping[type_id] << id if !id.nil?
  end

  def self.ids_to_type_imps(imps)
    imps.map{|implied_id| { implied_id: implied_id, tag_type_id: id } }
  end

  def self.ids_to_imps(tag_ids, imps)
    imps.map{|implied_id| tag_ids.map{ |tag_id| { tag_id: tag_id, implied_id: implied_id } } }.flatten
  end

  def unlink_tags
    Tag.where(tag_type_id: id).update_all(tag_type_id: 0, namespace: '')
  end
end
