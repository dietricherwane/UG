class AddPlrRaceNumberToUssdSessions < ActiveRecord::Migration
  def change
    add_column :ussd_sessions, :plr_race_number, :string
  end
end
