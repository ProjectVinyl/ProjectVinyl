module Taggable
  extend ActiveSupport::Concern

  included do
    scope :with_tags, -> { includes(:tags) } if respond_to? :scope

    def self.tag_relation(sym)
      define_method :__tag_relation do
        send(sym)
      end
    end
  end

  def tag_ids
    @tag_ids || (@tag_ids = tags.map(&:id))
  end

  def drop_tags(ids)
    __tag_relation.where('tag_id IN (?)', ids).destroy_all
  end

  def pick_up_tags(ids)
    __tag_relation
  end

  def tags_changed
    self.update_index(defer: false)
  end

  def tag_string
    Tag.tag_string(tags)
  end

  def tag_string=(value)
    set_tag_string value
  end

  def set_tag_string(value)
    set_all_tags(Tag.ids_from_string(value))
  end

  def set_all_tags(loaded)
    existing = __current_tags
    common = existing & loaded

    return nil if existing.length == loaded.length && existing.length == common.length

    __load_dif(loaded - common, existing - common, common)
  end

  def add_tag(tag_name)
    existing = __current_tags
    loaded = Tag.create_from_names([tag_name]) - existing

    return nil if loaded.empty?

    __load_dif(loaded, [], existing)
  end

  def add_tags(tags)
    tags = tags.uniq
    picked_up = pick_up_tags(tags)
    picked_up.create(tags.map{|o| { tag_id: o, o_tag_id: o } }) if !picked_up.nil?
  end

  private
  def __current_tags
    aliased_from = []
    aliased_to = []

    existing = tags.pluck(:id, :alias_id).map do |t|
      if t[1]
        aliased_from << t[0]
        aliased_to << t[1]
      end

      t[0]
    end

    if !aliased_from.empty?
      existing -= aliased_from
      aliased_to -= existing
      existing += aliased_to

      drop_tags aliased_from
      add_tags aliased_to
    end

    existing
  end

  def __load_dif(added, removed, existing)
    added = TagImplication.expand(added) if !added.empty?
    removed -= added if !added.empty? && !removed.empty?
    drop_tags(removed) if !removed.empty?

    if !added.empty?
      added -= existing
      add_tags added
    end

    tags_changed
    TagSubscription.notify_subscribers(added, removed, existing - removed)
    save

    [added, removed]
  end

end
