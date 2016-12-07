class AddEventsTrashToUssdSessions < ActiveRecord::Migration
  def change
    add_column :ussd_sessions, :events_trash, :text
  end
end
