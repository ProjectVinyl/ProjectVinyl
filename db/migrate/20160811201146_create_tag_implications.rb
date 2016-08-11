class CreateTagImplications < ActiveRecord::Migration
  def change
    create_table :tag_implications do |t|
      t.integer :tag_id
      t.integer :implied_id
    end
  end
end
