require 'projectvinyl/elasticsearch/opset'
require 'projectvinyl/elasticsearch/index'
require 'projectvinyl/elasticsearch/elastic_builder'
require 'projectvinyl/elasticsearch/activerecord/selector'

class SiteFilter < ApplicationRecord
  belongs_to :user

  def videos
    selector = ProjectVinyl::ElasticSearch::ActiveRecord::Selector.new(Video) {|results| load_model_data results.ids}
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
      @spoilered_id_cache |= ProjectVinyl::ElasticSearch::ActiveRecord::Selector.new(Video)
        .filter(__elastic_spoiler_params)
        .filter({ terms: { id: @pending_ids } })
        .ids
      @pending_ids = []
    end
    video && @spoilered_id_cache && @spoilered_id_cache.include?(video.id)
  end

  private
  def __filter_present?(filter)
    filter && !filter.strip.empty?
  end

  def __elastic_hide_params
    @hide_params || (@hide_params = __build_params(hide_filter))
  end

  def __elastic_spoiler_params
    @spoiler_params || (@spoiler_params = __build_params(spoiler_filter))
  end

  def __build_params(search_terms)
    ProjectVinyl::ElasticSearch::ElasticBuilder.interpret_opset(
      ProjectVinyl::ElasticSearch::Opset.new(search_terms, ProjectVinyl::ElasticSearch::Index::VIDEO_INDEX_PARAMS),
      user
    ).to_hash
  end
end
