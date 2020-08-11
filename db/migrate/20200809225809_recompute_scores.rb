class RecomputeScores < ActiveRecord::Migration[5.1]
  def change
    Video.reset_column_information
    Video.__elasticsearch__.create_index! index: 'wilson_lower_bound'
    Video.__elasticsearch__.create_index! index: 'boosted'

    Video.all.includes(:comment_thread).find_each(batch_size: 1000) do |video|
      video.compute_score
    end
  end
end
