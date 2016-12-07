class AddSpcBetTypeFieldsToUssdSessions < ActiveRecord::Migration
  def change
    add_column :ussd_sessions, :spc_bet_type_trash, :text
    add_column :ussd_sessions, :spc_bet_type_request, :text
    add_column :ussd_sessions, :spc_bet_type_response, :text
    add_column :ussd_sessions, :spc_event_description, :string
    add_column :ussd_sessions, :spc_event_pal_code, :string
    add_column :ussd_sessions, :spc_event_code, :string
  end
end
