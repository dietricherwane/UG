class CreateLogs < ActiveRecord::Migration
  def change
    create_table :logs do |t|
      t.string :msisdn
      t.string :gamer_id
      t.string :paymoney_account_number
      t.string :paymoney_password
      t.text :bet_request
      t.text :bet_response

      t.timestamps
    end
  end
end
