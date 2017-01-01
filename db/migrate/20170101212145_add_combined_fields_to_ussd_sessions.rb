class AddCombinedFieldsToUssdSessions < ActiveRecord::Migration
  def change
    add_column :ussd_sessions, :spc_combined, :boolean
    add_column :ussd_sessions, :spc_combined_string, :text
  end
end
