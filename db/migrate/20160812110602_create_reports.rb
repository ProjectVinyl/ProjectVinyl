class CreateReports < ActiveRecord::Migration
  def change
    create_table :reports do |t|
      t.integer :video_id
      t.integer :user_id
      t.string :first
      t.string :source
      t.boolean :content_type_unrelated
      t.boolean :content_type_offensive
      t.boolean :content_type_disturbing
      t.boolean :content_type_explicit
      t.string :copyright_holder
      t.text :copyright_usage
      t.boolean :copyright_accept
      t.string :subject
      t.text :other
      t.text :name
      t.text :contact
      t.timestamps null: false
    end
  end
end
