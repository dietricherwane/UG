class AddGetGamerIdFieldsToUssdSessions < ActiveRecord::Migration
  def change
    add_column :ussd_sessions, :get_gamer_id_request, :text
    add_column :ussd_sessions, :get_gamer_id_response, :text
  end
end
