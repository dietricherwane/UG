class CreateUssdSessions < ActiveRecord::Migration
  def change
    create_table :ussd_sessions do |t|
      t.string :session_identifier
      t.string :sender_cb
      t.string :parionsdirect_password_url
      t.text :parionsdirect_password_response
      t.string :parionsdirect_password
      t.string :parionsdirect_salt

      t.timestamps
    end
  end
end
