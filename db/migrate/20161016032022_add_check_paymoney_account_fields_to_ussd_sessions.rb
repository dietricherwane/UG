class AddCheckPaymoneyAccountFieldsToUssdSessions < ActiveRecord::Migration
  def change
    add_column :ussd_sessions, :check_pw_account_url, :text
    add_column :ussd_sessions, :check_pw_account_response, :text
    add_column :ussd_sessions, :pw_account_number, :string
    add_column :ussd_sessions, :pw_account_token, :string
  end
end
