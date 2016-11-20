class AddOtherOtpFieldsToUssdSessions < ActiveRecord::Migration
  def change
    add_column :ussd_sessions, :other_otp_paymoney_account_number, :string
    add_column :ussd_sessions, :other_otp_paymoney_account_password, :string
  end
end
