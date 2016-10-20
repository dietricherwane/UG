class AddPaymoneyOtpFieldsToUssdSessions < ActiveRecord::Migration
  def change
    add_column :ussd_sessions, :paymoney_otp_url, :text
    add_column :ussd_sessions, :paymoney_otp_response, :text
  end
end
