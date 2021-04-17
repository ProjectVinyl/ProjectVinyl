module VideoCacheHelper
  include FiltersHelper
  
  def cache_videos(elastic_record, key)
    ids = Rails.cache.fetch("#{current_filter.cache_key}.#{key}", expires_in: 1.minute) do
      elastic_record.ids
    end

    Video.where(id: ids).order("position(videos.id::text in '#{ids.join(',')}')")
  end
end
