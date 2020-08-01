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
    selector
  end

  def load_model_data(video_ids)
    if __filter_present? spoiler_filter
      @pending_ids = [] if !@pending_ids
      @pending_ids ||= video_ids
    end
  end

  def video_spoilered?(video)
    if @pending_ids && @pending_ids.length > 0
      @spoilered_id_cache = [] if !@spoilered_id_cache
      @spoilered_id_cache |= ProjectVinyl::Search::ActiveRecord.new(Video)
        .filter(__elastic_spoiler_params)
        .filter({ terms: { id: @pending_ids } })
        .ids
      @pending_ids = []
    end
    video && @spoilered_id_cache && @spoilered_id_cache.include?(video.id)
  end

  def build_params(search_terms, current_user = nil)
    ProjectVinyl::Search.interpret(search_terms, ProjectVinyl::Search::VIDEO_INDEX_PARAMS, current_user || user)
  end

  private
  def __filter_present?(filter)
    filter && !filter.strip.empty?
  end

  def __elastic_hide_params
    @hide_params || (@hide_params = build_params(hide_filter).to_hash)
  end

  def __elastic_spoiler_params
    @spoiler_params || (@spoiler_params = build_params(spoiler_filter).to_hash)
  end
end
