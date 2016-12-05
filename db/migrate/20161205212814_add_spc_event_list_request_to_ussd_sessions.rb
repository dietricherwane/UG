class AddSpcEventListRequestToUssdSessions < ActiveRecord::Migration
  def change
    add_column :ussd_sessions, :spc_event_list_request, :text
    add_column :ussd_sessions, :spc_event_list_response, :text
  end
end
