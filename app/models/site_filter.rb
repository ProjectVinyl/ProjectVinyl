require 'projectvinyl/search/search'
require 'projectvinyl/search/active_record'

class SiteFilter < ApplicationRecord
  belongs_to :user

  def can_modify?(user)
    user && !preferred && (user.id == user_id || user.is_staff?)
  end

  def toggle_tag_flags!(tag, hide, spoiler)
    tag = tag.actual
    self.hide_tags = __toggle_tag_in(tag, hide_tags, hide) if hides?(tag.id) != hide
    self.spoiler_tags = __toggle_tag_in(tag, spoiler_tags, spoiler) if spoilers?(tag.id) != spoiler
    save
  end

  def hides?(*tag_ids)
    @hidden_tag_ids = Tag.unscoped.split_to_ids(hide_tags) if !@hidden_tag_ids
    !(tag_ids & @hidden_tag_ids).empty?
  end

  def spoilers?(*tag_ids)
    @spoilered_tag_ids = Tag.unscoped.split_to_ids(spoiler_tags) if !@spoilered_tag_ids
    !(tag_ids & @spoilered_tag_ids).empty?
  end

  def spoiler_reason(video)
    return [] if !__spoilers_active?

    video.tags
      .filter{|tag| spoilers?(tag.id) }
      .map{|tag| tag.name }
  end

  def spoiler_image(video, fallback)
    reason = spoiler_reason(video)
    return fallback if reason.empty?

    "/spoiler_images/#{reason.first}.png"
  end

  def videos
    selector = ProjectVinyl::Search::ActiveRecord.new(Video) {|results| load_model_data results.ids}
    selector.must_not(__elastic_hide_params) if __filter_present? hide_filter
    selector.must_not(__elastic_hide_tag_params) if __filter_present? hide_tags
    selector
  end

  def video_spoilered?(video)
    return false if !(video || __spoilers_active?)
    load_model_data([video.id])
    !__get_or_load_unspoiler_cache.include?(video.id)
  end

  def load_model_data(video_ids)
    return if !__spoilers_active?

    video_ids = video_ids.uniq
    video_ids = video_ids.filter{|id| !__loaded_model_data?(id) }
    return if video_ids.empty?

    puts "[Filter] Queuing models #{video_ids}"
    @pending_ids = [] if !@pending_ids
    @pending_ids |= video_ids
  end

  def build_params(search_terms, current_user = nil)
    ProjectVinyl::Search.interpret(search_terms, ProjectVinyl::Search::VIDEO_INDEX_PARAMS, current_user || user)
  end

  private
  def __spoilers_active?
    __filter_present?(spoiler_filter) || __filter_present?(spoiler_tags)
  end

  def __loaded_model_data?(id)
    return true if @spoilered_id_cache && @spoilered_id_cache.include?(id)
    return true if @unspoilered_id_cache && @unspoilered_id_cache.include?(id)
    return true if @pending_ids && @pending_ids.include?(id)
    return false;
  end

  def __get_or_load_unspoiler_cache
    @spoilered_id_cache = [] if !@spoilered_id_cache
    @unspoilered_id_cache = [] if !@unspoilered_id_cache

    if @pending_ids && !@pending_ids.empty?
      puts "[Filter] Fetching spoilerage metadata for #{@pending_ids}"
      @spoiler_params = __build_spoiler_params if !@spoiler_params

      @spoilered_id_cache |= ProjectVinyl::Search::ActiveRecord.new(Video)
        .filter(@spoiler_params)
        .where(id: @pending_ids)
        .limit(@pending_ids.length)
        .ids
      @unspoilered_id_cache |= (@pending_ids - @spoilered_id_cache)
      @pending_ids = []

      puts "[Filter] Spoilered: #{@spoilered_id_cache}"
      puts "[Filter] Unspoilered: #{@unspoilered_id_cache}"
    end

    return @unspoilered_id_cache
  end

  def __toggle_tag_in(tag, tag_string, new_state)
    tags = Tag.unscoped.by_tag_string(tag_string)

    return Tag.tag_string(tags.where.not(id: tag.id)) if !new_state

    tags = tags.to_a
    tags << tag
    Tag.tag_string(tags)
  end

  def __filter_present?(filter)
    filter && !filter.strip.empty?
  end

  def __elastic_hide_tag_params
    @hide_tag_params || (@hide_tag_params = __build_tag_params(hide_tags))
  end

  def __elastic_hide_params
    @hide_params || (@hide_params = build_params(hide_filter).to_hash)
  end

  def __build_spoiler_params
    params = []
    params << __build_tag_params(spoiler_tags) if __filter_present?(spoiler_tags)
    params << build_params(spoiler_filter).to_hash if __filter_present?(spoiler_filter)
    {
      bool: {
        should: params,
        minimum_should_match: 1
      }
    }
  end

  def __build_tag_params(tag_string)
    { terms: { tags: Tag.unscoped.by_tag_string(tag_string).actual_names } }
  end

end
