require 'projectvinyl/elasticsearch/opset'
require 'projectvinyl/elasticsearch/index'
require 'projectvinyl/elasticsearch/elastic_builder'
require 'projectvinyl/elasticsearch/activerecord/selector'

class SiteFilter < ApplicationRecord
  belongs_to :user

  def videos
    selector = ProjectVinyl::ElasticSearch::ActiveRecord::Selector.new(Video) do |results|
      if __filter_present? spoiler_filter
        @spoilered_id_cache = [] if !@spoilered_id_cache
        @spoilered_id_cache |= ProjectVinyl::ElasticSearch::ActiveRecord::Selector.new(Video)
          .filter(__elastic_spoiler_params)
          .filter({ terms: { id: results.ids } })
          .ids
      end
    end

    selector.must_not(__elastic_hide_params) if __filter_present? hide_filter
    selector
  end

  def video_spoilered?(video)
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
    opset = ProjectVinyl::ElasticSearch::Opset.new(search_terms, ProjectVinyl::ElasticSearch::Index::VIDEO_INDEX_PARAMS)

    ProjectVinyl::ElasticSearch::ElasticBuilder.interpret_opset(opset, user).to_hash
  end
end
