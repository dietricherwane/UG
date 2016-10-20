class AddPaymoneySoldFieldsToUssdSessions < ActiveRecord::Migration
  def change
    add_column :ussd_sessions, :paymoney_sold_url, :text
    add_column :ussd_sessions, :paymoney_sold_response, :text
  end
end
