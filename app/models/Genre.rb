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
    if tag_string == ''
      return []
    end
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
    target.destroy
    Genre.getGenresFor(tag_string).each_with_index do |genre, index|
      target.create(genre_id: genre.id)
    end
  end
end