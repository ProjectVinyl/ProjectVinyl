class CreateStoryCards < ActiveRecord::Migration[5.1]
  def change
    create_table :story_cards do |t|
      t.integer :video_id
      t.string :style, default: :video
      t.integer :left, default: 0.5
      t.integer :top, default: 0.5
      t.integer :width, default: 0.5
      t.integer :height, default: 0.5
      t.integer :start_time, default: 0
      t.integer :end_time, default: 0
      t.string :title
      t.string :metadata
      t.string :image
      t.string :url
    end
  end
end
