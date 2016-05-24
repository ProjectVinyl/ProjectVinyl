# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ name: 'Chicago' }, { name: 'Copenhagen' }])
#   Mayor.create(name: 'Emanuel', city: cities.first)

# authors = Artist.create([{ id: 1, name: 'Dr. Sample', description: 'This is a sample artist, for testing purposes', bio: 'Short description', mime: ''} ])
# authors.first.videos.create([{ id: 1, title: 'The Real Pinkie Pie', description: 'Everypony stay pinkie! :pinkiesmile:', audio_only: true, mime: '', file: '' }])
# authors.first.videos.create([{ id: 2, title: 'Brushie Brush', description: 'PSA From Colgate: Everypony brush your teeth. You disgust me.', audio_only: false, mime: '', file: '' }])

# album = authors.first.albums.create([{ id: 1, title: 'Sample\' Samples', description: 'No description'}]).first

# album.album_items.create([{ id: 1, index: 1, video_id: 1}])
# album.album_items.create([{ id: 2, index: 2, video_id: 2}])

Genre.create([
  { id: 1, name: 'Electro-pop', description: '' },
  { id: 2, name: 'Dubstep', description: '' },
  { id: 3, name: 'Fusion', description: '' },
  { id: 4, name: 'World', description: '' },
  { id: 5, name: 'Blues', description: '' },
  { id: 6, name: 'Classical', description: '' },
  { id: 7, name: 'Country', description: '' },
  { id: 8, name: 'Electroswing', description: '' },
  { id: 9, name: 'Techno', description: '' },
  { id: 10, name: 'Easy Listening', description: '' },
  { id: 11, name: 'Chiptune', description: '' },
  { id: 12, name: 'Industrial', description: '' },
  { id: 13, name: 'IDM/Experimental', description: '' },
  { id: 14, name: 'Hip-hop', description: '' },
  { id: 15, name: 'Rap', description: '' },
  { id: 16, name: 'Holiday', description: '' },
  { id: 17, name: 'Gospel', description: '' },
  { id: 18, name: 'Instrumental', description: '' },
  { id: 19, name: 'Pop', description: '' },
  { id: 20, name: 'Jazz', description: '' },
  { id: 21, name: 'Gypsy', description: '' },
  { id: 22, name: 'Rock', description: '' },
  { id: 23, name: 'R&B/Soul', description: '' },
  { id: 24, name: 'Reggae', description: '' },
  { id: 25, name: 'Folk', description: '' },
  { id: 26, name: 'Soundtrack', description: '' },
  { id: 27, name: 'Showtunes', description: 'Sweetie Belle\' favourite' },
  { id: 28, name: 'Remix', description: '' }
])

Artist.find(1).artist_genres.create([
  { genre_id: 1 }, { genre_id: 2 }, { genre_id: 15 }
])
Video.find(1).video_genres.create([{ genre_id: 15 }])
Video.find(2).video_genres.create([{ genre_id: 28 }])