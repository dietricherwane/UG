class AddAlrPlaceBetFieldsToUssdSessions < ActiveRecord::Migration
  def change
    add_column :ussd_sessions, :alr_place_bet_request, :text
    add_column :ussd_sessions, :alr_place_bet_response, :text
  end
end
