class Artist < ActiveRecord::Base

end

class MergeArtistsIntoUsers < ActiveRecord::Migration
  def change
    add_column :users, :username, :string
    add_column :users, :safe_name, :string
    add_column :users, :description, :text
    add_column :users, :bio, :text
    add_column :users, :mime, :string
    add_column :users, :banner_set, :boolean, default: false
    add_column :users, :tag_id, :integer
    add_column :users, :star_id, :integer
    add_index :users, :username, unique: true
    add_index :users, :tag_id
    User.reset_column_information
    
    add_column :artist_genres, :user_id, :integer
    add_index :artist_genres, :user_id
    ArtistGenre.reset_column_information
    
    add_column :videos, :user_id, :integer
    add_column :videos, :safe_title, :string
    add_index :videos, :user_id
    Video.reset_column_information
    
    add_column :albums, :hidden, :boolean, default: false
    Album.reset_column_information
    Album.all.each do |album|
      if album.owner_type == 'User'
        album.hidden = true
        album.save
      end
    end
    
    User.all.each do |user|
      if user.artist_id && artist = Artist.where(id: user.artist_id).first
        user.username = artist.name
        user.safe_name = PathHelper.url_safe(artist.name)
        user.description = artist.description
        user.bio = artist.bio
        user.mime = artist.mime
        user.banner_set = artist.banner_set
        user.tag_id = artist.tag_id
      else
        user.username = 'Background Pony #' + user.id.to_s
        user.safe_name = ''
        user.banner_set = false
      end
      if star = Album.where(owner_id: user.id, owner_type: "User").first
        user.star_id = star.id
      end
      user.save
    end
    
    ArtistGenre.all.each do |i|
      if !self.artist_to_user(i)
        i.destroy
      end
    end
    Video.all.each do |i|
      i.safe_title = PathHelper.url_safe(i.title)
      self.artist_to_user(i)
    end
  end
  
  def artist_to_user(i)
      if (user = User.where(artist_id: i.artist_id).first)
        i.user_id = user.id
        i.save
        return true
      end
      return false
  end
end
