class AddAlrBetIdToUssdSessions < ActiveRecord::Migration
  def change
    add_column :ussd_sessions, :alr_bet_id, :string
  end
end
