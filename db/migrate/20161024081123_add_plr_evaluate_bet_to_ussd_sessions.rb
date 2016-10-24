class AddPlrEvaluateBetToUssdSessions < ActiveRecord::Migration
  def change
    add_column :ussd_sessions, :plr_evaluate_bet_request, :text
    add_column :ussd_sessions, :plr_evaluate_bet_response, :text
  end
end
