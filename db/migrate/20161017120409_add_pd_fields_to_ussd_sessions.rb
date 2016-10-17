class AddPdFieldsToUssdSessions < ActiveRecord::Migration
  def change
    add_column :ussd_sessions, :pd_account_created, :boolean
    add_column :ussd_sessions, :pw_account_created, :boolean
  end
end
