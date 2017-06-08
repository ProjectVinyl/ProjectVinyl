# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ name: 'Chicago' }, { name: 'Copenhagen' }])
#   Mayor.create(name: 'Emanuel', city: cities.first)

Genre.create([
  { name: 'Electro-pop', description: '' },
  { name: 'Dubstep', description: '' },
  { name: 'Fusion', description: '' },
  { name: 'World', description: '' },
  { name: 'Blues', description: '' },
  { name: 'Classical', description: '' },
  { name: 'Country', description: '' },
  { name: 'Electroswing', description: '' },
  { name: 'Techno', description: '' },
  { name: 'Easy Listening', description: '' },
  { name: 'Chiptune', description: '' },
  { name: 'Industrial', description: '' },
  { name: 'IDM/Experimental', description: '' },
  { name: 'Hip-hop', description: '' },
  { name: 'Rap', description: '' },
  { name: 'Holiday', description: '' },
  { name: 'Gospel', description: '' },
  { name: 'Instrumental', description: '' },
  { name: 'Pop', description: '' },
  { name: 'Jazz', description: '' },
  { name: 'Gypsy', description: '' },
  { name: 'Rock', description: '' },
  { name: 'R&B/Soul', description: '' },
  { name: 'Reggae', description: '' },
  { name: 'Folk', description: '' },
  { name: 'Soundtrack', description: '' },
  { name: 'Showtunes', description: 'Sweetie Belle\' favourite' },
  { name: 'Remix', description: '' }
])

artist = Artist.create([
  { name: 'Dr. Sample', description: 'This is a sample artist for testing purposes only!', bio: 'Short description', mime: '', banner_set: false }
]).first
artist.videos.create([
  { title: 'The Real Pinkie Pie', description: 'Everypony stay pinkie! :pinkiesmile:', audio_only: true, mime: '', file: '' },
  { title: 'Brushie Brush', description: 'PSA From Colgate: Everypony brush your teeth. You disgust me.', audio_only: false, mime: '', file: '' }
])

album = artist.albums.create([
  { title: 'Sample\' Samples', description: 'No description' }
]).first
album.album_items.create([
  { index: 1, video_id: 1 }
])
album.album_items.create([
  { index: 2, video_id: 2 }
])

artist.artist_genres.create([
  { genre_id: 1 }, { genre_id: 2 }, { genre_id: 15 }
])
artist.videos.first.video_genres.create([
  { genre_id: 15 }
])
artist.videos.second.video_genres.create([
  { genre_id: 28 }
])
