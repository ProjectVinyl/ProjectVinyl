class CreateTags < ActiveRecord::Migration
  def change
    create_table :tags do |t|
      t.string :name
      t.text :description
      t.integer :tag_type_id
    end
    create_table :tag_types do |t|
      t.string :prefix
      t.string :colour
    end
    TagType.create([
      { prefix: "artist", colour: "#3a3" },
      { prefix: "genre", colour: "#33a" }
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
    Artist.reset_column_information
    Artist.all.each do |a|
      a.tag = Tag.create(description: "", tag_type_id: 1).set_name(a.name)
      a.save
    end
  end
end
