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

ActiveRecord::Schema.define(version: 20160904213842) do

  create_table "album_items", force: :cascade do |t|
    t.integer "album_id", limit: 4
    t.integer "video_id", limit: 4
    t.integer "index",    limit: 4
  end

  add_index "album_items", ["album_id"], name: "index_album_items_on_album_id", using: :btree
  add_index "album_items", ["video_id"], name: "index_album_items_on_video_id", using: :btree

  create_table "albums", force: :cascade do |t|
    t.string   "title",            limit: 255
    t.text     "description",      limit: 65535
    t.datetime "created_at",                                     null: false
    t.datetime "updated_at",                                     null: false
    t.integer  "user_id",          limit: 4
    t.integer  "featured",         limit: 4,     default: 0
    t.boolean  "hidden",                         default: false
    t.string   "safe_title",       limit: 255
    t.text     "html_description", limit: 65535
  end

  add_index "albums", ["user_id"], name: "index_albums_on_user_id", using: :btree

  create_table "artist_genres", force: :cascade do |t|
    t.integer "tag_id",  limit: 4
    t.integer "user_id", limit: 4
  end

  add_index "artist_genres", ["user_id"], name: "index_artist_genres_on_user_id", using: :btree

  create_table "comment_replies", force: :cascade do |t|
    t.integer "parent_id",  limit: 4
    t.integer "comment_id", limit: 4
  end

  create_table "comment_threads", force: :cascade do |t|
    t.string   "title",          limit: 255, default: ""
    t.integer  "user_id",        limit: 4
    t.datetime "created_at",                                 null: false
    t.datetime "updated_at",                                 null: false
    t.integer  "owner_id",       limit: 4
    t.string   "owner_type",     limit: 255
    t.boolean  "locked",                     default: false
    t.boolean  "pinned",                     default: false
    t.integer  "total_comments", limit: 4,   default: 0
    t.string   "safe_title",     limit: 255
  end

  add_index "comment_threads", ["owner_type", "owner_id"], name: "index_comment_threads_on_owner_type_and_owner_id", using: :btree

  create_table "comments", force: :cascade do |t|
    t.integer  "user_id",           limit: 4
    t.integer  "comment_thread_id", limit: 4
    t.text     "html_content",      limit: 65535
    t.text     "bbc_content",       limit: 65535
    t.datetime "created_at",                                      null: false
    t.datetime "updated_at",                                      null: false
    t.boolean  "hidden",                          default: false
  end

  create_table "notifications", force: :cascade do |t|
    t.string   "message",    limit: 255
    t.string   "source",     limit: 255
    t.integer  "user_id",    limit: 4
    t.string   "sender",     limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "unread",                 default: true
  end

  create_table "processing_workers", force: :cascade do |t|
    t.boolean "running",               default: false
    t.string  "status",  limit: 255,   default: ""
    t.text    "message", limit: 65535
  end

  create_table "reports", force: :cascade do |t|
    t.integer  "comment_thread_id",       limit: 4
    t.integer  "user_id",                 limit: 4
    t.string   "first",                   limit: 255
    t.string   "source",                  limit: 255
    t.boolean  "content_type_unrelated"
    t.boolean  "content_type_offensive"
    t.boolean  "content_type_disturbing"
    t.boolean  "content_type_explicit"
    t.string   "copyright_holder",        limit: 255
    t.text     "copyright_usage",         limit: 65535
    t.boolean  "copyright_accept"
    t.string   "subject",                 limit: 255
    t.text     "other",                   limit: 65535
    t.text     "name",                    limit: 65535
    t.text     "contact",                 limit: 65535
    t.datetime "created_at",                            null: false
    t.datetime "updated_at",                            null: false
    t.integer  "video_id",                limit: 4
    t.boolean  "resolved"
  end

  create_table "tag_implications", force: :cascade do |t|
    t.integer "tag_id",     limit: 4
    t.integer "implied_id", limit: 4
  end

  create_table "tag_subscriptions", force: :cascade do |t|
    t.integer  "user_id",    limit: 4
    t.integer  "tag_id",     limit: 4
    t.datetime "created_at",                           null: false
    t.datetime "updated_at",                           null: false
    t.boolean  "watch",                default: false
    t.boolean  "spoiler",              default: false
    t.boolean  "hide",                 default: false
  end

  create_table "tag_type_implications", force: :cascade do |t|
    t.integer "tag_type_id", limit: 4
    t.integer "implied_id",  limit: 4
  end

  create_table "tag_types", force: :cascade do |t|
    t.string "prefix", limit: 255
  end

  create_table "tags", force: :cascade do |t|
    t.string  "name",        limit: 255,   default: ""
    t.text    "description", limit: 65535
    t.integer "tag_type_id", limit: 4
    t.string  "short_name",  limit: 255,   default: ""
    t.integer "video_count", limit: 4,     default: 0
    t.integer "user_count",  limit: 4,     default: 0
    t.integer "alias_id",    limit: 4
  end

  create_table "users", force: :cascade do |t|
    t.string   "email",                  limit: 255,   default: "",    null: false
    t.string   "encrypted_password",     limit: 255,   default: "",    null: false
    t.string   "reset_password_token",   limit: 255
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",          limit: 4,     default: 0,     null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string   "current_sign_in_ip",     limit: 255
    t.string   "last_sign_in_ip",        limit: 255
    t.datetime "created_at",                                           null: false
    t.datetime "updated_at",                                           null: false
    t.boolean  "is_admin",                             default: false
    t.integer  "notification_count",     limit: 4,     default: 0
    t.string   "username",               limit: 255
    t.string   "safe_name",              limit: 255
    t.text     "description",            limit: 65535
    t.text     "bio",                    limit: 65535
    t.string   "mime",                   limit: 255
    t.boolean  "banner_set",                           default: false
    t.integer  "tag_id",                 limit: 4
    t.integer  "star_id",                limit: 4
    t.text     "html_description",       limit: 65535
    t.text     "html_bio",               limit: 65535
    t.integer  "feed_count",             limit: 4,     default: 0
  end

  add_index "users", ["email"], name: "index_users_on_email", unique: true, using: :btree
  add_index "users", ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true, using: :btree
  add_index "users", ["tag_id"], name: "index_users_on_tag_id", using: :btree
  add_index "users", ["username"], name: "index_users_on_username", unique: true, using: :btree

  create_table "video_genres", force: :cascade do |t|
    t.integer "video_id", limit: 4
    t.integer "tag_id",   limit: 4
  end

  add_index "video_genres", ["video_id"], name: "index_video_genres_on_video_id", using: :btree

  create_table "videos", force: :cascade do |t|
    t.string   "title",             limit: 255
    t.text     "description",       limit: 65535
    t.boolean  "audio_only"
    t.string   "mime",              limit: 255
    t.string   "file",              limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "upvotes",           limit: 4
    t.integer  "downvotes",         limit: 4
    t.integer  "length",            limit: 4
    t.integer  "score",             limit: 4,     default: 0
    t.boolean  "hidden",                          default: false
    t.integer  "views",             limit: 4,     default: 0
    t.boolean  "processed"
    t.string   "source",            limit: 255,   default: ""
    t.integer  "user_id",           limit: 4
    t.string   "safe_title",        limit: 255
    t.integer  "comment_thread_id", limit: 4
    t.text     "html_description",  limit: 65535
    t.boolean  "featured",                        default: false
  end

  add_index "videos", ["created_at"], name: "index_videos_on_created_at", using: :btree
  add_index "videos", ["user_id"], name: "index_videos_on_user_id", using: :btree

  create_table "votes", force: :cascade do |t|
    t.integer  "user_id",    limit: 4
    t.integer  "video_id",   limit: 4
    t.boolean  "negative"
    t.datetime "created_at",           null: false
    t.datetime "updated_at",           null: false
  end

end
