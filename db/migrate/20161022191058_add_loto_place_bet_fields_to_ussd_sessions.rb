class AddLotoPlaceBetFieldsToUssdSessions < ActiveRecord::Migration
  def change
    add_column :ussd_sessions, :loto_bet_paymoney_password, :string
    add_column :ussd_sessions, :loto_place_bet_url, :text
    add_column :ussd_sessions, :loto_place_bet_response, :text
  end
end
