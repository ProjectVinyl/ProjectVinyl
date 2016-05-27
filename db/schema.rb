# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20160527133142) do

  create_table "album_items", force: :cascade do |t|
    t.integer "album_id", limit: 4
    t.integer "video_id", limit: 4
    t.integer "index",    limit: 4
  end

  add_index "album_items", ["album_id"], name: "index_album_items_on_album_id", using: :btree
  add_index "album_items", ["video_id"], name: "index_album_items_on_video_id", using: :btree

  create_table "albums", force: :cascade do |t|
    t.integer  "artist_id",   limit: 4
    t.string   "title",       limit: 255
    t.text     "description", limit: 65535
    t.datetime "created_at",                null: false
    t.datetime "updated_at",                null: false
  end

  add_index "albums", ["artist_id"], name: "index_albums_on_artist_id", using: :btree

  create_table "artist_genres", force: :cascade do |t|
    t.integer "artist_id", limit: 4
    t.integer "genre_id",  limit: 4
  end

  add_index "artist_genres", ["artist_id"], name: "index_artist_genres_on_artist_id", using: :btree
  add_index "artist_genres", ["genre_id"], name: "index_artist_genres_on_genre_id", using: :btree

  create_table "artists", force: :cascade do |t|
    t.string   "name",        limit: 255
    t.text     "description", limit: 65535
    t.text     "bio",         limit: 65535
    t.string   "mime",        limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "banner_set"
  end

  create_table "genres", force: :cascade do |t|
    t.string "name",        limit: 255
    t.text   "description", limit: 65535
  end

  create_table "video_genres", force: :cascade do |t|
    t.integer "video_id", limit: 4
    t.integer "genre_id", limit: 4
  end

  add_index "video_genres", ["genre_id"], name: "index_video_genres_on_genre_id", using: :btree
  add_index "video_genres", ["video_id"], name: "index_video_genres_on_video_id", using: :btree

  create_table "videos", force: :cascade do |t|
    t.integer  "artist_id",   limit: 4
    t.string   "title",       limit: 255
    t.text     "description", limit: 65535
    t.boolean  "audio_only"
    t.string   "mime",        limit: 255
    t.string   "file",        limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "upvotes",     limit: 4
    t.integer  "downvotes",   limit: 4
    t.integer  "length",      limit: 4
    t.integer  "score",       limit: 4,     default: 0
  end

  add_index "videos", ["artist_id"], name: "index_videos_on_artist_id", using: :btree
  add_index "videos", ["created_at"], name: "index_videos_on_created_at", using: :btree

end
