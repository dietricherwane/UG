class AddSpcTournamentTrashToUssdSessions < ActiveRecord::Migration
  def change
    add_column :ussd_sessions, :tournaments_trash, :text
  end
end
