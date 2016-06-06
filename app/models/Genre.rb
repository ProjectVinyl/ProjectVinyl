class Genre < ActiveRecord::Base
  has_many :video_genres
  has_many :videos, :through => :video_genres
  has_many :artist_genres
  has_many :artists, :through => :artist_genres
  
  def self.tag_string(genres)
    result = ''
    genres.each do |i|
      if result.length > 0
        result = result + ','
      end
      result = result + i.name
    end
    return result
  end
  
  def self.getGenresFor(tag_string)
    tag_string = tag_string.downcase.split(/ |,|;/)
    built = ''
    tag_string.each do |item|
      if built != ''
        built = built + ' OR '
      end
      built = built + 'lower(name) = ?'
    end
    return Genre.where(built, *tag_string)
  end
  
  def self.loadGenres(tag_string, target)
    load = Genre.getGenresFor(tag_string)
    if load.size != target.size
      if target.size > load.size
        target.each_with_index do |item, index|
          if index >= load.size
            item.destroy
          end
        end
      end
    end
    loaded = target.offset(0)
    load.each_with_index do |genre, index|
      item = loaded[index]
      if item
        item.genre = genre
        item.save
      else
        target.create(genre_id: genre.id)
      end
    end
  end
end