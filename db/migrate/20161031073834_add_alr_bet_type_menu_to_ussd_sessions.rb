class AddAlrBetTypeMenuToUssdSessions < ActiveRecord::Migration
  def change
    add_column :ussd_sessions, :alr_bet_type_menu, :string
  end
end
