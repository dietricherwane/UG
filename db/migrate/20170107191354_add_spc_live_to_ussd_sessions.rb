class AddSpcLiveToUssdSessions < ActiveRecord::Migration
  def change
    add_column :ussd_sessions, :spc_live, :boolean
  end
end
