class CreateComments < ActiveRecord::Migration
  def change
    create_table :comments do |t|
      t.integer :user_id
      t.integer :parent_id
      t.integer :video_id
      t.text :html_content
      t.text :bbc_content
      t.timestamps null: false
    end
  end
end
