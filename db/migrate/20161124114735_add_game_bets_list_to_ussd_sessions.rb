class AddGameBetsListToUssdSessions < ActiveRecord::Migration
  def change
    add_column :ussd_sessions, :loto_bets_list_request, :text
    add_column :ussd_sessions, :loto_bets_list_response, :text
    add_column :ussd_sessions, :plr_bets_list_request, :text
    add_column :ussd_sessions, :plr_bets_list_response, :text
    add_column :ussd_sessions, :alr_bet_list_request, :text
    add_column :ussd_sessions, :alr_bets_list_response, :text
    add_column :ussd_sessions, :spc_bets_list_request, :text
    add_column :ussd_sessions, :spc_bets_list_response, :text
  end
end
