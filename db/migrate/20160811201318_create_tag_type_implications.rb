class CreateTagTypeImplications < ActiveRecord::Migration
  def change
    create_table :tag_type_implications do |t|
      t.integer :tag_type_id
      t.integer :implied_id
    end
  end
end
