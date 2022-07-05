module Sources
  class ImportJob < ApplicationJob
    queue_as :high_priority

    def perform()
      ExternalSource.delete_all
      Video.where.not(source: nil).where.not(source: '').in_batches do |videos|
        ExternalSource.upsert_all(
          videos.pluck(:id, :source).map{|row| ExternalSource.attributes_for_url(row[0], row[1]) }.map do |row|
            row[:created_at] = Time.zone.now
            row[:updated_at] = row[:created_at]
            row
          end,
          unique_by: [:video_id, :url]
        )
      end
    end
  end
end
