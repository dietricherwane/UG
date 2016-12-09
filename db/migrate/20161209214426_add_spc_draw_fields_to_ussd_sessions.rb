class AddSpcDrawFieldsToUssdSessions < ActiveRecord::Migration
  def change
    add_column :ussd_sessions, :spc_draw_trash, :text
    add_column :ussd_sessions, :spc_draw_request, :text
    add_column :ussd_sessions, :spc_draw_response, :text
    add_column :ussd_sessions, :spc_bet_description, :string
    add_column :ussd_sessions, :spc_bet_code, :string
  end
end
