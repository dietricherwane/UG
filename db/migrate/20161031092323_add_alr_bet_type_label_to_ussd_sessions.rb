class AddAlrBetTypeLabelToUssdSessions < ActiveRecord::Migration
  def change
    add_column :ussd_sessions, :alr_bet_type_label, :string
  end
end
