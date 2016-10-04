class CreateUssdReceptionLogs < ActiveRecord::Migration
  def change
    create_table :ussd_reception_logs do |t|
      t.string :received_parmeters

      t.timestamps
    end
  end
end
