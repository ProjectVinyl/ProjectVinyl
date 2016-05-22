class CreateVideos < ActiveRecord::Migration
  def change
    create_table :videos do |t|
      t.integer :artist_id
      t.string :title
      t.text :description
      t.boolean :audio_only
      t.string :mime
      t.string :file

      t.timestamps            null: true
    end
    add_index :videos, :artist_id
  end
end
