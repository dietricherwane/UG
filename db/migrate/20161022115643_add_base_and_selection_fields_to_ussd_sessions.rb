class AddBaseAndSelectionFieldsToUssdSessions < ActiveRecord::Migration
  def change
    add_column :ussd_sessions, :base_field, :string
    add_column :ussd_sessions, :selection_field, :string
  end
end
