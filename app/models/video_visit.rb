class VideoVisit < ApplicationRecord
  include Statable
  visitable :ahoy_visit

  belongs_to :video
  belongs_to :ahoy_visit, class_name: "Ahoy::Visit"

  scope :pie_data, ->(current_domain) {
    joins(:ahoy_visit)
      .select("COUNT(*) AS total, referring_domain")
      .where.not('ahoy_visits.referring_domain': ['', current_domain])
      .group('ahoy_visits.referring_domain')
      .order('total')
  }
end
