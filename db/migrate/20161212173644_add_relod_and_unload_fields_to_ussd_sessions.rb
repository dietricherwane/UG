class AddRelodAndUnloadFieldsToUssdSessions < ActiveRecord::Migration
  def change
    add_column :ussd_sessions, :reload_account, :string
    add_column :ussd_sessions, :reload_amount, :string
    add_column :ussd_sessions, :reload_request, :text
    add_column :ussd_sessions, :reload_response, :text
    add_column :ussd_sessions, :unload_account, :string
    add_column :ussd_sessions, :unload_amount, :string
    add_column :ussd_sessions, :unload_request, :text
    add_column :ussd_sessions, :unload_response, :text
  end
end
