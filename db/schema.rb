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

ActiveRecord::Schema.define(version: 20180324081050) do

  create_table "album_items", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci" do |t|
    t.integer "album_id"
    t.integer "video_id"
    t.integer "index"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer "o_video_id", default: 0
    t.index ["album_id"], name: "index_album_items_on_album_id"
    t.index ["video_id"], name: "index_album_items_on_video_id"
  end

  create_table "albums", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci" do |t|
    t.string "title", limit: 340
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id"
    t.integer "featured", default: 0
    t.boolean "hidden", default: false
    t.string "safe_title", limit: 340
    t.text "html_description"
    t.boolean "reverse_ordering", default: false
    t.integer "ordering", default: 0
    t.integer "listing", default: 0
    t.index ["user_id"], name: "index_albums_on_user_id"
  end

  create_table "artist_genres", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci" do |t|
    t.integer "tag_id"
    t.integer "user_id"
    t.integer "o_tag_id"
    t.index ["user_id"], name: "index_artist_genres_on_user_id"
  end

  create_table "badges", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci" do |t|
    t.string "title"
    t.string "colour"
    t.string "icon"
    t.integer "badge_type", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "note"
    t.string "description"
    t.boolean "hidden", default: false
  end

  create_table "boards", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci" do |t|
    t.string "title"
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "short_name"
  end

  create_table "comment_replies", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci" do |t|
    t.integer "parent_id"
    t.integer "comment_id"
  end

  create_table "comment_threads", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci" do |t|
    t.string "title", limit: 340
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "owner_id"
    t.string "owner_type"
    t.boolean "locked", default: false
    t.boolean "pinned", default: false
    t.integer "total_comments", default: 0
    t.string "safe_title", limit: 340
    t.index ["owner_type", "owner_id"], name: "index_comment_threads_on_owner_type_and_owner_id"
  end

  create_table "comment_votes", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci" do |t|
    t.integer "user_id"
    t.integer "comment_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "comments", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci" do |t|
    t.integer "user_id"
    t.integer "comment_thread_id"
    t.text "html_content"
    t.text "bbc_content"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "hidden", default: false
    t.integer "o_comment_thread_id", default: 0
    t.integer "score"
  end

  create_table "notifications", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci" do |t|
    t.string "message", limit: 340
    t.string "source"
    t.integer "user_id"
    t.string "sender"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean "unread", default: true
  end

  create_table "pms", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci" do |t|
    t.integer "state", default: 0
    t.boolean "unread", default: false
    t.integer "sender_id"
    t.integer "receiver_id"
    t.integer "comment_thread_id"
    t.integer "new_comment_id"
    t.integer "user_id"
  end

  create_table "processing_workers", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci" do |t|
    t.boolean "running", default: true
    t.string "status", default: ""
    t.text "message", limit: 16777215
    t.integer "video_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "reports", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci" do |t|
    t.integer "reportable_id"
    t.integer "user_id"
    t.boolean "resolved"
    t.string "first", limit: 340
    t.string "source", limit: 340
    t.boolean "content_type_unrelated"
    t.boolean "content_type_offensive"
    t.boolean "content_type_disturbing"
    t.boolean "content_type_explicit"
    t.string "copyright_holder", limit: 340
    t.text "copyright_usage"
    t.boolean "copyright_accept"
    t.string "subject", limit: 340
    t.text "other", limit: 16777215
    t.text "name", limit: 16777215
    t.text "contact", limit: 16777215
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "reportable_type"
  end

  create_table "site_notices", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci" do |t|
    t.boolean "active", default: true
    t.string "message"
    t.string "html_message"
  end

  create_table "tag_histories", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci" do |t|
    t.integer "video_id"
    t.integer "tag_id"
    t.integer "user_id"
    t.boolean "added"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "value"
  end

  create_table "tag_implications", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci" do |t|
    t.integer "tag_id"
    t.integer "implied_id"
  end

  create_table "tag_subscriptions", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci" do |t|
    t.integer "user_id"
    t.integer "tag_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "watch", default: false
    t.boolean "spoiler", default: false
    t.boolean "hide", default: false
  end

  create_table "tag_type_implications", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci" do |t|
    t.integer "tag_type_id"
    t.integer "implied_id"
  end

  create_table "tag_types", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci" do |t|
    t.string "prefix"
    t.boolean "hidden", default: true
  end

  create_table "tags", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci" do |t|
    t.string "name", default: ""
    t.text "description", limit: 16777215
    t.integer "tag_type_id"
    t.string "short_name", default: ""
    t.integer "video_count", default: 1
    t.integer "user_count", default: 1
    t.integer "alias_id"
    t.index ["name"], name: "index_tags_on_name", unique: true
  end

  create_table "thread_subscriptions", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci" do |t|
    t.integer "user_id"
    t.integer "comment_thread_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "user_badges", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci" do |t|
    t.integer "badge_id"
    t.integer "user_id"
    t.string "custom_title"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "users", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci" do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer "sign_in_count", default: 0, null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string "current_sign_in_ip"
    t.string "last_sign_in_ip"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "notification_count", default: 0
    t.string "username", limit: 340
    t.string "safe_name", limit: 340
    t.text "description"
    t.text "bio"
    t.string "mime"
    t.boolean "banner_set", default: false, null: false
    t.integer "tag_id"
    t.integer "star_id"
    t.text "html_description"
    t.text "html_bio"
    t.integer "feed_count", default: 0, null: false
    t.integer "role", default: 0, null: false
    t.string "preferences"
    t.string "confirmation_token"
    t.datetime "confirmed_at"
    t.datetime "confirmation_sent_at"
    t.string "unconfirmed_email"
    t.datetime "cached_at"
    t.index ["confirmation_token"], name: "index_users_on_confirmation_token", unique: true
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["tag_id"], name: "index_users_on_tag_id"
    t.index ["username"], name: "index_users_on_username", unique: true
  end

  create_table "video_genres", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci" do |t|
    t.integer "video_id"
    t.integer "tag_id"
    t.integer "o_tag_id"
    t.index ["video_id"], name: "index_video_genres_on_video_id"
  end

  create_table "videos", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci" do |t|
    t.string "title", limit: 340
    t.text "description"
    t.boolean "audio_only"
    t.string "mime"
    t.string "file"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer "upvotes"
    t.integer "downvotes"
    t.integer "length"
    t.integer "score", default: 0
    t.boolean "hidden", default: false
    t.integer "views", default: 0
    t.boolean "processed"
    t.string "source", limit: 340
    t.integer "user_id"
    t.string "safe_title", limit: 340
    t.integer "comment_thread_id"
    t.text "html_description"
    t.boolean "featured", default: false
    t.string "checksum", limit: 32
    t.integer "heat"
    t.integer "duplicate_id", default: 0
    t.datetime "cached_at"
    t.index ["checksum"], name: "index_videos_on_checksum"
    t.index ["created_at"], name: "index_videos_on_created_at"
    t.index ["user_id"], name: "index_videos_on_user_id"
  end

  create_table "votes", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci" do |t|
    t.integer "user_id"
    t.integer "video_id"
    t.boolean "negative"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

end
