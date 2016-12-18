class AddSpcEventDateAndSpcEventTimeToUssdSessions < ActiveRecord::Migration
  def change
    add_column :ussd_sessions, :spc_event_date, :string
    add_column :ussd_sessions, :spc_event_time, :string
  end
end
