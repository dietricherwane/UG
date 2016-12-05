class AddSpcTournamentLabelAndSpcTournamentCodeToUssdSessions < ActiveRecord::Migration
  def change
    add_column :ussd_sessions, :spc_tournament_label, :string
    add_column :ussd_sessions, :spc_tournament_code, :string
  end
end
