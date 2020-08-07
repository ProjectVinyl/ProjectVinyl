require 'projectvinyl/search/search'
require 'projectvinyl/search/active_record'

class SiteFilter < ApplicationRecord
  belongs_to :user

  def can_modify?(user)
    user && !preferred && (user.id == user_id || user.is_staff?)
  end

  def videos
    selector = ProjectVinyl::Search::ActiveRecord.new(Video) {|results| load_model_data results.ids}
    selector.must_not(__elastic_hide_params) if __filter_present? hide_filter
    selector.must_not(__elastic_hide_tag_params) if __filter_present? hide_tags
    selector
  end

  def load_model_data(video_ids)
    if __filter_present? spoiler_filter
      puts "[Filter] Queuing models #{video_ids}"
      @pending_ids = [] if !@pending_ids
      @pending_ids |= video_ids
    end
  end

  def video_spoilered?(video)
    return false if @unspoilered_id_cache && @unspoilered_id_cache.include?(video.id)

    if video && !(@spoilered_id_cache && @spoilered_id_cache.include?(video.id)) && !(@pending_ids && @pending_ids.include?(video.id))
      puts "[Filter] Force Loading video spoilerage metadata for #{video.id}"
      load_model_data([video.id])
    end

    if @pending_ids && @pending_ids.length > 0
      puts "[Filter] Fetching spoilerage metadata for #{@pending_ids}"
      @spoilered_id_cache = [] if !@spoilered_id_cache
      @unspoilered_id_cache = [] if !@unspoilered_id_cache
      @spoilered_id_cache |= ProjectVinyl::Search::ActiveRecord.new(Video)
        .filter({
          bool: {
            should: [ __elastic_spoiler_params, __elastic_spoiler_tag_params ],
            minimum_should_match: 1
          }
        })
        .where(id: @pending_ids)
        .limit(@pending_ids.length)
        .ids
      @unspoilered_id_cache |= (@pending_ids - @spoilered_id_cache)
      @pending_ids = []

      puts "[Filter] Spoilered: #{@spoilered_id_cache}"
      puts "[Filter] Unspoilered: #{@unspoilered_id_cache}"
    end

    video && @spoilered_id_cache && @spoilered_id_cache.include?(video.id)
  end

  def build_params(search_terms, current_user = nil)
    ProjectVinyl::Search.interpret(search_terms, ProjectVinyl::Search::VIDEO_INDEX_PARAMS, current_user || user)
  end

  def toggle_tag_flags!(tag, hide, spoiler)
    tag = tag.actual

    if hides?(tag.id) != hide
      self.hide_tags = __toggle_tag_in(tag, hide_tags, hide)
      @hidden_tag_ids = nil
    end

    if spoilers?(tag.id) != spoiler
      self.spoiler_tags = __toggle_tag_in(tag, spoiler_tags, spoiler)
      @spoilered_tag_ids = nil
    end

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

  private
  def __toggle_tag_in(tag, tag_string, new_state)
    tags = Tag.unscoped.by_tag_string(tag_string)
    puts tags

    return Tag.tag_string(tags.where.not(id: tag.id)) if !new_state

    tags = tags.to_a
    tags << tag

    puts tags.map{|m| m.name}.join(',')
    Tag.tag_string(tags)
  end

  def __filter_present?(filter)
    filter && !filter.strip.empty?
  end

  def __build_tag_params(tag_string)
    { terms: { tags: Tag.unscoped.by_tag_string(tag_string).actual_names } }
  end

  def __elastic_hide_tag_params
    @hide_tag_params || (@hide_tag_params = __build_tag_params(hide_tags))
  end

  def __elastic_spoiler_tag_params
    @spoiler_tag_params || (@spoiler_tag_params = __build_tag_params(spoiler_tags))
  end

  def __elastic_hide_params
    @hide_params || (@hide_params = build_params(hide_filter).to_hash)
  end

  def __elastic_spoiler_params
    @spoiler_params || (@spoiler_params = build_params(spoiler_filter).to_hash)
  end
end
