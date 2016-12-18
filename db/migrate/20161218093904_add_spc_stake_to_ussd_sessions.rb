class AddSpcStakeToUssdSessions < ActiveRecord::Migration
  def change
    add_column :ussd_sessions, :spc_stake, :string
  end
end
