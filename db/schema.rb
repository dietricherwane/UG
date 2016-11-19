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

ActiveRecord::Schema.define(version: 20161119201628) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "account_profiles", force: true do |t|
    t.string   "msisdn"
    t.string   "paymoney_account_number"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "correlators", force: true do |t|
    t.string   "correlator_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "delayed_jobs", force: true do |t|
    t.integer  "priority",   default: 0, null: false
    t.integer  "attempts",   default: 0, null: false
    t.text     "handler",                null: false
    t.text     "last_error"
    t.datetime "run_at"
    t.datetime "locked_at"
    t.datetime "failed_at"
    t.string   "locked_by"
    t.string   "queue"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "delayed_jobs", ["priority", "run_at"], name: "delayed_jobs_priority", using: :btree

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
    t.string   "error_code"
    t.text     "error_message"
    t.boolean  "status"
    t.string   "correlator_id"
    t.string   "operation_type"
    t.text     "time_trail"
  end

  create_table "parameters", force: true do |t|
    t.string   "gateway_url"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "paymoney_url"
    t.string   "paymoney_wallet_url"
    t.string   "parionsdirect_url"
  end

  create_table "ussd_reception_logs", force: true do |t|
    t.string   "received_parmeters"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text     "received_parameters"
    t.string   "rev_id"
    t.string   "rev_password"
    t.string   "sp_id"
    t.string   "service_id"
    t.string   "timestamp"
    t.string   "trace_unique_id"
    t.string   "msg_type"
    t.string   "sender_cb"
    t.string   "receiver_cb"
    t.string   "ussd_of_type"
    t.string   "msisdn"
    t.string   "service_code"
    t.string   "code_scheme"
    t.string   "ussd_string"
    t.string   "error_code"
    t.string   "error_message"
    t.boolean  "status"
    t.string   "remote_ip"
    t.string   "time_trail"
  end

  create_table "ussd_sessions", force: true do |t|
    t.string   "session_identifier"
    t.string   "sender_cb"
    t.string   "parionsdirect_password_url"
    t.text     "parionsdirect_password_response"
    t.string   "parionsdirect_password"
    t.string   "parionsdirect_salt"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "creation_pd_password"
    t.string   "creation_pd_password_confirmation"
    t.text     "creation_pd_request"
    t.text     "creation_pd_response"
    t.text     "creation_pw_request"
    t.text     "creation_pw_response"
    t.string   "connection_pd_pasword"
    t.text     "check_pw_account_url"
    t.text     "check_pw_account_response"
    t.string   "pw_account_number"
    t.string   "pw_account_token"
    t.boolean  "pd_account_created"
    t.boolean  "pw_account_created"
    t.text     "paymoney_sold_url"
    t.text     "paymoney_sold_response"
    t.text     "paymoney_otp_url"
    t.text     "paymoney_otp_response"
    t.string   "draw_day_label"
    t.string   "draw_day_shortcut"
    t.string   "bet_selection"
    t.string   "bet_selection_shortcut"
    t.string   "formula_label"
    t.string   "formula_shortcut"
    t.string   "base_field"
    t.string   "selection_field"
    t.string   "stake"
    t.string   "loto_bet_paymoney_password"
    t.text     "loto_place_bet_url"
    t.text     "loto_place_bet_response"
    t.text     "get_gamer_id_request"
    t.text     "get_gamer_id_response"
    t.text     "get_plr_race_list_request"
    t.text     "get_plr_race_list_response"
    t.string   "plr_reunion_number"
    t.string   "plr_race_number"
    t.text     "plr_race_details_request"
    t.text     "plr_race_details_response"
    t.string   "plr_bet_type_label"
    t.string   "plr_bet_type_shortcut"
    t.string   "plr_formula_label"
    t.string   "plr_formula_shortcut"
    t.string   "plr_base"
    t.string   "plr_selection"
    t.string   "plr_number_of_times"
    t.text     "plr_evaluate_bet_request"
    t.text     "plr_evaluate_bet_response"
    t.string   "bet_cost_amount"
    t.text     "plr_place_bet_request"
    t.text     "plr_place_bet_response"
    t.string   "alr_full_box"
    t.text     "alr_get_current_program_request"
    t.text     "alr_get_current_program_response"
    t.string   "alr_program_id"
    t.string   "alr_program_date"
    t.string   "alr_program_status"
    t.string   "alr_race_ids"
    t.text     "alr_race_list_request"
    t.text     "alr_race_list_response"
    t.text     "race_data"
    t.string   "national_label"
    t.string   "national_shortcut"
    t.string   "alr_bet_type_menu"
    t.string   "alr_bet_type_label"
    t.string   "alr_formula_label"
    t.string   "alr_formula_shortcut"
    t.string   "alr_base"
    t.string   "alr_selection"
    t.string   "full_formula_boolean"
    t.boolean  "full_formula"
    t.string   "alr_stake"
    t.text     "alr_evaluate_bet_request"
    t.text     "alr_evaluate_bet_response"
    t.string   "alr_bet_id"
    t.string   "alr_scratched_list"
    t.string   "alr_combinations"
    t.string   "alr_amount"
    t.text     "alr_place_bet_request"
    t.text     "alr_place_bet_response"
    t.string   "other_paymoney_account_number"
    t.string   "other_paymoney_account_password"
  end

end
