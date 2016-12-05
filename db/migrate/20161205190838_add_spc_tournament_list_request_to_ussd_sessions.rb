class AddSpcTournamentListRequestToUssdSessions < ActiveRecord::Migration
  def change
    add_column :ussd_sessions, :spc_tournament_list_request, :text
    add_column :ussd_sessions, :spc_tournament_list_response, :text
  end
end
