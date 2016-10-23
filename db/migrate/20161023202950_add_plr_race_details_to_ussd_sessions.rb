class AddPlrRaceDetailsToUssdSessions < ActiveRecord::Migration
  def change
    add_column :ussd_sessions, :plr_race_details_request, :text
    add_column :ussd_sessions, :plr_race_details_response, :text
  end
end
