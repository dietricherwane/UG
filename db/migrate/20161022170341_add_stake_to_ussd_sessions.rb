class AddStakeToUssdSessions < ActiveRecord::Migration
  def change
    add_column :ussd_sessions, :stake, :string
  end
end
