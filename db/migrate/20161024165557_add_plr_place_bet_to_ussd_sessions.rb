class AddPlrPlaceBetToUssdSessions < ActiveRecord::Migration
  def change
    add_column :ussd_sessions, :bet_cost_amount, :string
    add_column :ussd_sessions, :plr_place_bet_request, :text
    add_column :ussd_sessions, :plr_place_bet_response, :text
  end
end
