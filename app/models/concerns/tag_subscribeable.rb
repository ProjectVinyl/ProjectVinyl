module TagSubscribeable
	extend ActiveSupport::Concern

  def watched_tag_string
    Tag.tag_string(watched_tags)
  end

  def hides?(*tag_ids)
    site_filter && site_filter.hides?(*tag_ids)
  end

  def spoilers?(*tag_ids)
    site_filter && site_filter.spoilers?(*tag_ids)
  end

  def watches?(*tag_ids)
    @watched_tag_ids ||= watched_tags.actual_ids
    !(tag_ids & @watched_tag_ids).empty?
  end
end
