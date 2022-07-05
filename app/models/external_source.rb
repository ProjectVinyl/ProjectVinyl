require 'projectvinyl/web/youtube'

class ExternalSource < ApplicationRecord
  include Upsert

  belongs_to :video

  scope :youtube, -> { where(provider: 'youtube') }
  scope :jsons, -> {
    pluck(:url).map do |url|
      { namespace: '', name: url, slug: url }
    end
  }

  def self.attributes_for_url(video_id, url)
    key = ProjectVinyl::Web::Youtube.video_id(url)

    {
      video_id: video_id,
      url: url,
      key: key,
      provider: key.nil? ? nil : 'youtube'
    }
  end
end
