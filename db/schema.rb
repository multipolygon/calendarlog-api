# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `rails
# db:schema:load`. When creating a new database, `rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 2020_07_01_034310) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "locations", force: :cascade do |t|
    t.bigint "user_id"
    t.text "title"
    t.text "street_address"
    t.text "town_suburb"
    t.text "post_code"
    t.text "region"
    t.float "latitude"
    t.float "longitude"
    t.datetime "last_record_at"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.bigint "old_id"
    t.datetime "deleted_at"
    t.text "country"
    t.jsonb "precipitation"
    t.jsonb "temperature_min"
    t.jsonb "temperature_max"
    t.index ["last_record_at"], name: "idx_16395_index_locations_on_last_record_at"
    t.index ["old_id"], name: "idx_16395_index_locations_on_old_id"
    t.index ["title"], name: "idx_16395_index_locations_on_title"
    t.index ["user_id"], name: "idx_16395_index_locations_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.text "username"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text "email"
    t.text "password_digest"
    t.boolean "admin"
    t.text "verification_token"
    t.text "verified_email"
    t.bigint "feedback_rating"
    t.text "feedback_text"
    t.index ["username"], name: "idx_16404_index_users_on_username"
  end

end
