class AddConnectionPdPasswordToUssdSessions < ActiveRecord::Migration
  def change
    add_column :ussd_sessions, :connection_pd_pasword, :string
  end
end
