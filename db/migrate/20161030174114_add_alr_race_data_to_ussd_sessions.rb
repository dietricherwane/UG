class AddAlrRaceDataToUssdSessions < ActiveRecord::Migration
  def change
    add_column :ussd_sessions, :race_data, :text
  end
end
