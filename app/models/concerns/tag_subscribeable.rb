module TagSubscribeable
	extend ActiveSupport::Concern

  def watched_tag_string
    Tag.tag_string(watched_tags_actual)
  end

  def hides?(*tags)
    site_filter && site_filter.hides?(*tags)
  end

  def spoilers?(*tags)
    site_filter && site_filter.spoilers?(*tags)
  end

  def watches(tag)
    @watched_tag_ids ||= watched_tags_actual.pluck_actual_ids
    !([tag.id] & @watched_tag_ids).empty?
  end
end
