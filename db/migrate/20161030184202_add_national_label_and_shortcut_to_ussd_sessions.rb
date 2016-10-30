class AddNationalLabelAndShortcutToUssdSessions < ActiveRecord::Migration
  def change
    add_column :ussd_sessions, :national_label, :string
    add_column :ussd_sessions, :national_shortcut, :string
  end
end
