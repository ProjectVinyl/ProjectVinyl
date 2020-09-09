class CreateVideoChapter < ActiveRecord::Migration[5.1]
  def change
    create_table :video_chapters do |t|
      t.integer :video_id
      t.text :title
      t.float :timestamp
    end
  end
end
