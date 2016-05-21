class CreateVideos < ActiveRecord::Migration
  def change
    create_table :videos do |t|
      t.string :title
      t.text :description
      t.boolean :audio_only
      t.integer :artist_id
      t.binary :cover,         :null => false
      t.string :mime
      t.binary :file,          :null => false

      t.timestamps,            :null => true
    end
  end
end
