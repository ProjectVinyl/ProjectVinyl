class CreateVideoExternalSource < ActiveRecord::Migration[5.1]
  def change
    create_table :external_sources do |t|
      t.integer :video_id
      t.string :provider
      t.string :key
      t.timestamps null: false
    end
    add_index :external_sources, [:provider, :key]
  end
end
