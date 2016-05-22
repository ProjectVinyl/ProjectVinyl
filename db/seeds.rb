# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ name: 'Chicago' }, { name: 'Copenhagen' }])
#   Mayor.create(name: 'Emanuel', city: cities.first)

authors = Artist.create([{ id: 1, name: 'Dr. Sample', description: 'This is a sample artist, for testing purposes', bio: 'Short description', mime: ''} ])
authors.first.videos.create([{ id: 1, title: 'The Real Pinkie Pie', description: 'Everypony stay pinkie! :pinkiesmile:', audio_only: true, mime: '', file: '' }])
authors.first.videos.create([{ id: 2, title: 'Brushie Brush', description: 'PSA From Colgate: Everypony brush your teeth. You disgust me.', audio_only: false, mime: '', file: '' }])

album = authors.first.albums.create([{ id: 1, title: 'Sample\' Samples', description: 'No description'}]).first

album.album_items.create([{ id: 1, index: 1, video_id: 1}])
album.album_items.create([{ id: 2, index: 2, video_id: 2}])