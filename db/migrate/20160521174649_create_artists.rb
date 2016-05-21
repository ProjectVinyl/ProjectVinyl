class CreateArtists < ActiveRecord::Migration
  def change
    create_table :artists do |t|
      t.string :name
      t.text :description
      t.text :bio
      t.binary :avatar,      :null => false
      t.string :mime

      t.timestamps           :null => true
    end
  end
end
