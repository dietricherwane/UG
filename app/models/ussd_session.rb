class UssdSession < ActiveRecord::Base
  attr_accessible :session_identifier, :sender_cb, :parionsdirect_password_url, :parionsdirect_password_response, :parionsdirect_password, :parionsdirect_salt, :creation_pd_password, :creation_pd_password_confirmation, :creation_pd_request, :creation_pd_response, :creation_pw_request, :creation_pw_response, :pd_account_created, :pw_account_created, :connection_pd_pasword, :check_pw_account_url, :check_pw_account_response, :pw_account_number, :pw_account_token, :paymoney_sold_url, :paymoney_sold_response, :paymoney_otp_url, :paymoney_otp_response, :draw_day_label, :draw_day_shortcut, :bet_selection, :bet_selection_shortcut, :formula_label, :formula_shortcut, :base_field, :selection_field, :stake, :loto_bet_paymoney_password, :loto_place_bet_url, :loto_place_bet_response, :get_gamer_id_request, :get_gamer_id_response, :get_plr_race_list_request, :get_plr_race_list_response, :plr_reunion_number, :plr_race_number, :plr_race_details_request, :plr_race_details_response, :plr_bet_type_label, :plr_bet_type_shortcut, :plr_formula_label, :plr_formula_shortcut, :plr_base, :plr_selection, :plr_number_of_times, :plr_evaluate_bet_request, :plr_evaluate_bet_response, :plr_place_bet_request, :plr_place_bet_response, :alr_full_box, :alr_get_current_program_request, :alr_get_current_program_response, :alr_program_id, :alr_program_date, :alr_program_status, :alr_race_ids, :alr_race_list_request, :alr_race_list_response, :race_data, :national_label, :national_shortcut, :alr_bet_type_menu, :alr_bet_type_label, :alr_formula_label, :alr_formula_shortcut, :alr_base, :alr_selection, :full_formula_boolean, :full_formula, :alr_stake, :alr_evaluate_bet_request, :alr_evaluate_bet_response, :alr_bet_id, :alr_scratched_list, :alr_combinations, :alr_amount, :alr_place_bet_request, :alr_place_bet_response, :bet_cost_amount, :other_paymoney_account_number, :other_paymoney_account_password, :other_otp_paymoney_account_number, :other_otp_paymoney_account_password, :loto_bets_list_request, :loto_bets_list_response, :plr_bets_list_request, :plr_bets_list_response, :alr_bet_list_request, :alr_bet_list_response, :spc_bets_list_request, :spc_bets_list_response, :list_sportcash_sports_request, :list_sportcash_sports_response, :sportcash_sport_label, :sportcash_sport_code, :list_spc_sport
end
