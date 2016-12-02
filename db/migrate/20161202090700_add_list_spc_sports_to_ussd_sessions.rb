class AddListSpcSportsToUssdSessions < ActiveRecord::Migration
  def change
    add_column :ussd_sessions, :list_spc_sport, :text
  end
end
