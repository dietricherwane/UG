class AddDrawDayFieldsToUssdSessions < ActiveRecord::Migration
  def change
    add_column :ussd_sessions, :draw_day_label, :string
    add_column :ussd_sessions, :draw_day_shortcut, :string
  end
end
