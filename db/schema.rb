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

ActiveRecord::Schema.define(version: 20161003081913) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "account_profiles", force: true do |t|
    t.string   "msisdn"
    t.string   "paymoney_account_number"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "generic_logs", force: true do |t|
    t.text     "operation"
    t.text     "request_log"
    t.text     "response_log"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "logs", force: true do |t|
    t.string   "msisdn"
    t.string   "gamer_id"
    t.string   "paymoney_account_number"
    t.string   "paymoney_password"
    t.text     "bet_request"
    t.text     "bet_response"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "status"
    t.string   "drawing"
    t.string   "bet"
    t.string   "formula"
  end

  create_table "mtn_start_session_logs", force: true do |t|
    t.text     "request_log"
    t.text     "response_log"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "request_code"
    t.string   "total_time"
    t.text     "request_headers"
    t.string   "request_url"
  end

  create_table "parameters", force: true do |t|
    t.string   "gateway_url"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "paymoney_url"
    t.string   "paymoney_wallet_url"
    t.string   "parionsdirect_url"
  end

end
