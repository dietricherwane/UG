class AddCheckReunionFieldsToUssdSessions < ActiveRecord::Migration
  def change
    add_column :ussd_sessions, :get_plr_race_list_request, :text
    add_column :ussd_sessions, :get_plr_race_list_response, :text
    add_column :ussd_sessions, :plr_reunion_number, :string
  end
end
