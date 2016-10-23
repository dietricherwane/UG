class AddPlrBetTypeFieldsToUssdSessions < ActiveRecord::Migration
  def change
    add_column :ussd_sessions, :plr_bet_type_label, :string
    add_column :ussd_sessions, :plr_bet_type_shortcut, :string
  end
end
