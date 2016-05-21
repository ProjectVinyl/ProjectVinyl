# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ name: 'Chicago' }, { name: 'Copenhagen' }])
#   Mayor.create(name: 'Emanuel', city: cities.first)

authors = Artist.create([{ id: 1, name: 'Dr. Sample', description: 'This is a sample artist, for testing purposes', bio: 'Short description', avatar: '/avatars/1.png'} ])
videos = Video.create([{ id: 1, title: 'The Real Pinkie Pie', description: 'Everypony stay pinkie! :pinkiesmile:', audio_only: true, artist_id: 1, cover: '/cover/1.png' }])