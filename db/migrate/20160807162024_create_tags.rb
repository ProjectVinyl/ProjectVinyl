class Genre < ActiveRecord::Base
end
class CreateTags < ActiveRecord::Migration
  def change
    create_table :tags do |t|
      t.string :name, default: ""
      t.string :short_name, default: ""
      t.text :description
      t.integer :tag_type_id
    end
    create_table :tag_types do |t|
      t.string :prefix
    end
    TagType.create([
      { prefix: "artist" },
      { prefix: "genre" }
    ])
    add_column :artist_genres, :tag_id, :integer
    ArtistGenre.reset_column_information
    add_column :video_genres, :tag_id, :integer
    ArtistGenre.reset_column_information
    connection = ActiveRecord::Base.connection
    Genre.all.each do |item|
      genre_tag = Tag.create(description: item.description, tag_type_id: 2).set_name(item.name)
      connection.execute('UPDATE `artist_genres` SET `artist_genres`.`tag_id` = ' + genre_tag.id.to_s + ' WHERE `artist_genres`.`genre_id` = ' + item.id.to_s);
      connection.execute('UPDATE `video_genres` SET `video_genres`.`tag_id` = ' + genre_tag.id.to_s + ' WHERE `video_genres`.`genre_id` = ' + item.id.to_s);
    end
    add_column :artists, :tag_id, :integer
    add_index :artists, :tag_id
    remove_column :artist_genres, :genre_id
    remove_column :video_genres, :genre_id
    add_index :artists, :name, unique: true
  end
end
