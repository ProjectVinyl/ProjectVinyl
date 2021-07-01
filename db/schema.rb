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

ActiveRecord::Schema.define(version: 20210701160352) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "ahoy_events", force: :cascade do |t|
    t.bigint "visit_id"
    t.bigint "user_id"
    t.string "name"
    t.json "properties"
    t.datetime "time"
    t.index ["name", "time"], name: "index_ahoy_events_on_name_and_time"
    t.index ["user_id"], name: "index_ahoy_events_on_user_id"
    t.index ["visit_id"], name: "index_ahoy_events_on_visit_id"
  end

  create_table "ahoy_visits", force: :cascade do |t|
    t.string "visit_token"
    t.string "visitor_token"
    t.bigint "user_id"
    t.string "ip"
    t.text "user_agent"
    t.text "referrer"
    t.string "referring_domain"
    t.text "landing_page"
    t.string "browser"
    t.string "os"
    t.string "device_type"
    t.string "country"
    t.string "region"
    t.string "city"
    t.string "utm_source"
    t.string "utm_medium"
    t.string "utm_term"
    t.string "utm_content"
    t.string "utm_campaign"
    t.datetime "started_at"
    t.index ["user_id"], name: "index_ahoy_visits_on_user_id"
    t.index ["visit_token"], name: "index_ahoy_visits_on_visit_token", unique: true
  end

  create_table "album_items", id: :serial, force: :cascade do |t|
    t.integer "album_id"
    t.integer "video_id"
    t.integer "index"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer "o_video_id", default: 0
    t.index ["album_id"], name: "index_album_items_on_album_id"
    t.index ["video_id"], name: "index_album_items_on_video_id"
  end

  create_table "albums", id: :serial, force: :cascade do |t|
    t.string "title", limit: 340
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id"
    t.integer "featured", default: 0
    t.boolean "hidden", default: false
    t.string "safe_title", limit: 340
    t.boolean "reverse_ordering", default: false
    t.integer "ordering", default: 0
    t.integer "listing", default: 0
    t.integer "views", default: 0
    t.index ["user_id"], name: "index_albums_on_user_id"
  end

  create_table "api_tokens", force: :cascade do |t|
    t.integer "user_id"
    t.string "token"
    t.integer "hits", default: 0
    t.datetime "reset_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "total_hits", default: 0
    t.index ["token"], name: "index_api_tokens_on_token", unique: true
    t.index ["user_id"], name: "index_api_tokens_on_user_id"
  end

  create_table "artist_genres", id: :serial, force: :cascade do |t|
    t.integer "tag_id"
    t.integer "user_id"
    t.integer "o_tag_id"
    t.index ["user_id"], name: "index_artist_genres_on_user_id"
  end

  create_table "badges", id: :serial, force: :cascade do |t|
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

  create_table "boards", id: :serial, force: :cascade do |t|
    t.string "title"
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "short_name"
  end

  create_table "comment_replies", id: :serial, force: :cascade do |t|
    t.integer "parent_id"
    t.integer "comment_id"
    t.index ["comment_id"], name: "index_comment_replies_on_comment_id"
    t.index ["parent_id"], name: "index_comment_replies_on_parent_id"
  end

  create_table "comment_threads", id: :serial, force: :cascade do |t|
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

  create_table "comment_votes", id: :serial, force: :cascade do |t|
    t.integer "user_id"
    t.integer "comment_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["comment_id"], name: "index_comment_votes_on_comment_id"
  end

  create_table "comments", id: :serial, force: :cascade do |t|
    t.integer "user_id"
    t.integer "comment_thread_id"
    t.text "bbc_content"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "hidden", default: false
    t.integer "o_comment_thread_id", default: 0
    t.string "moderation_note"
    t.integer "likes_count"
    t.integer "anonymous_id", default: 0
    t.index ["comment_thread_id"], name: "index_comments_on_comment_thread_id"
  end

  create_table "notification_receivers", force: :cascade do |t|
    t.integer "user_id"
    t.string "endpoint"
    t.string "auth"
    t.string "pauth"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_notification_receivers_on_user_id"
  end

  create_table "notifications", id: :serial, force: :cascade do |t|
    t.string "message", limit: 340
    t.string "source"
    t.integer "user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean "unread", default: true
    t.integer "owner_id"
    t.text "owner_type"
    t.index ["user_id"], name: "index_notifications_on_user_id"
  end

  create_table "pms", id: :serial, force: :cascade do |t|
    t.integer "state", default: 0
    t.boolean "unread", default: false
    t.integer "sender_id"
    t.integer "receiver_id"
    t.integer "comment_thread_id"
    t.integer "new_comment_id"
    t.integer "user_id"
    t.index ["receiver_id"], name: "index_pms_on_receiver_id"
    t.index ["sender_id"], name: "index_pms_on_sender_id"
    t.index ["state"], name: "index_pms_on_state"
    t.index ["unread"], name: "index_pms_on_unread"
    t.index ["user_id"], name: "index_pms_on_user_id"
  end

  create_table "profile_modules", force: :cascade do |t|
    t.integer "user_id"
    t.integer "column"
    t.integer "index"
    t.string "module_type"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id", "column"], name: "index_profile_modules_on_user_id_and_column"
  end

  create_table "reports", id: :serial, force: :cascade do |t|
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
    t.text "other"
    t.text "name"
    t.text "contact"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "reportable_type"
    t.index ["reportable_id", "reportable_type"], name: "index_reports_on_reportable_id_and_reportable_type"
    t.index ["user_id"], name: "index_reports_on_user_id"
  end

  create_table "site_filters", force: :cascade do |t|
    t.text "name"
    t.text "description"
    t.integer "user_id"
    t.text "hide_filter"
    t.text "spoiler_filter"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "preferred"
    t.text "spoiler_tags"
    t.text "hide_tags"
    t.index ["user_id"], name: "index_site_filters_on_user_id"
  end

  create_table "site_notices", force: :cascade do |t|
    t.boolean "active", default: true
    t.string "message"
    t.index ["active"], name: "index_site_notices_on_active"
  end

  create_table "tag_histories", id: :serial, force: :cascade do |t|
    t.integer "video_id"
    t.integer "tag_id"
    t.integer "user_id"
    t.boolean "added"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "value"
    t.index ["tag_id"], name: "index_tag_histories_on_tag_id"
    t.index ["user_id"], name: "index_tag_histories_on_user_id"
    t.index ["video_id"], name: "index_tag_histories_on_video_id"
  end

  create_table "tag_implications", id: :serial, force: :cascade do |t|
    t.integer "tag_id"
    t.integer "implied_id"
    t.index ["implied_id"], name: "index_tag_implications_on_implied_id"
    t.index ["tag_id", "implied_id"], name: "index_tag_implications_on_tag_id_and_implied_id", unique: true
    t.index ["tag_id"], name: "index_tag_implications_on_tag_id"
  end

  create_table "tag_rules", force: :cascade do |t|
    t.string "message"
    t.integer "when_present", default: [], array: true
    t.integer "all_of", default: [], array: true
    t.integer "none_of", default: [], array: true
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "any_of", default: [], array: true
  end

  create_table "tag_subscriptions", id: :serial, force: :cascade do |t|
    t.integer "user_id"
    t.integer "tag_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["tag_id"], name: "index_tag_subscriptions_on_tag_id"
    t.index ["user_id"], name: "index_tag_subscriptions_on_user_id"
  end

  create_table "tag_type_implications", id: :serial, force: :cascade do |t|
    t.integer "tag_type_id"
    t.integer "implied_id"
  end

  create_table "tag_types", id: :serial, force: :cascade do |t|
    t.string "prefix"
    t.boolean "hidden", default: true
    t.boolean "user_assignable", default: true
    t.index ["prefix"], name: "index_tag_types_on_prefix", unique: true
  end

  create_table "tags", id: :serial, force: :cascade do |t|
    t.string "name", default: ""
    t.text "description"
    t.integer "tag_type_id"
    t.string "short_name", default: ""
    t.integer "video_count", default: 1
    t.integer "user_count", default: 1
    t.integer "alias_id"
    t.string "namespace", default: ""
    t.string "suffex", default: ""
    t.string "slug", default: ""
    t.index ["name"], name: "index_tags_on_name", unique: true
  end

  create_table "thread_subscriptions", id: :serial, force: :cascade do |t|
    t.integer "user_id"
    t.integer "comment_thread_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["comment_thread_id"], name: "index_thread_subscriptions_on_comment_thread_id"
    t.index ["user_id"], name: "index_thread_subscriptions_on_user_id"
  end

  create_table "user_badges", id: :serial, force: :cascade do |t|
    t.integer "badge_id"
    t.integer "user_id"
    t.string "custom_title"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["badge_id"], name: "index_user_badges_on_badge_id"
    t.index ["user_id"], name: "index_user_badges_on_user_id"
  end

  create_table "users", id: :serial, force: :cascade do |t|
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
    t.integer "feed_count", default: 0, null: false
    t.integer "role", default: 0, null: false
    t.string "preferences"
    t.string "confirmation_token"
    t.datetime "confirmed_at"
    t.datetime "confirmation_sent_at"
    t.string "unconfirmed_email"
    t.datetime "cached_at"
    t.datetime "last_active_at"
    t.integer "default_listing", default: 0
    t.string "time_zone"
    t.integer "site_filter_id", default: 0
    t.integer "message_count", default: 0
    t.index ["confirmation_token"], name: "index_users_on_confirmation_token", unique: true
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["tag_id"], name: "index_users_on_tag_id"
    t.index ["username"], name: "index_users_on_username", unique: true
  end

  create_table "video_chapters", force: :cascade do |t|
    t.integer "video_id"
    t.text "title"
    t.float "timestamp"
    t.index ["video_id"], name: "index_video_chapters_on_video_id"
  end

  create_table "video_genres", id: :serial, force: :cascade do |t|
    t.integer "video_id"
    t.integer "tag_id"
    t.integer "o_tag_id"
    t.index ["tag_id"], name: "index_video_genres_on_tag_id"
    t.index ["video_id"], name: "index_video_genres_on_video_id"
  end

  create_table "video_visits", force: :cascade do |t|
    t.integer "video_id"
    t.integer "ahoy_visit_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["ahoy_visit_id"], name: "index_video_visits_on_ahoy_visit_id"
    t.index ["video_id"], name: "index_video_visits_on_video_id"
  end

  create_table "videos", id: :serial, force: :cascade do |t|
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
    t.boolean "featured", default: false
    t.string "checksum", limit: 32
    t.float "heat"
    t.integer "duplicate_id", default: 0
    t.datetime "cached_at"
    t.string "moderation_note"
    t.integer "width"
    t.integer "height"
    t.integer "play_count", default: 0
    t.integer "listing", default: 0
    t.datetime "premiered_at"
    t.float "wilson_lower_bound"
    t.float "wilson_upper_bound"
    t.datetime "boosted_at"
    t.integer "framerate"
    t.integer "favourites"
    t.index ["checksum"], name: "index_videos_on_checksum"
    t.index ["created_at"], name: "index_videos_on_created_at"
    t.index ["user_id"], name: "index_videos_on_user_id"
  end

  create_table "votes", id: :serial, force: :cascade do |t|
    t.integer "user_id"
    t.integer "video_id"
    t.boolean "negative"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_votes_on_user_id"
    t.index ["video_id"], name: "index_votes_on_video_id"
  end

  create_table "watch_histories", force: :cascade do |t|
    t.integer "user_id"
    t.integer "video_id"
    t.integer "watch_time"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_watch_histories_on_user_id"
    t.index ["video_id"], name: "index_watch_histories_on_video_id"
  end

end
