class CreateAccountProfiles < ActiveRecord::Migration
  def change
    create_table :account_profiles do |t|
      t.string :msisdn
      t.string :paymoney_account_number

      t.timestamps
    end
  end
end
