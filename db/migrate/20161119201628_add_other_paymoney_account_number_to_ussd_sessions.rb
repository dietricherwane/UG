class AddOtherPaymoneyAccountNumberToUssdSessions < ActiveRecord::Migration
  def change
    add_column :ussd_sessions, :other_paymoney_account_number, :string
    add_column :ussd_sessions, :other_paymoney_account_password, :string
  end
end
