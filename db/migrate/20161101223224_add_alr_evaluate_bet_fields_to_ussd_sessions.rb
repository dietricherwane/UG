class AddAlrEvaluateBetFieldsToUssdSessions < ActiveRecord::Migration
  def change
    add_column :ussd_sessions, :alr_stake, :string
    add_column :ussd_sessions, :alr_evaluate_bet_request, :text
    add_column :ussd_sessions, :alr_evaluate_bet_response, :text
  end
end
