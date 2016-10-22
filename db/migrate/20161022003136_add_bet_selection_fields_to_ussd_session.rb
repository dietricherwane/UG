class AddBetSelectionFieldsToUssdSession < ActiveRecord::Migration
  def change
    add_column :ussd_sessions, :bet_selection, :string
    add_column :ussd_sessions, :bet_selection_shortcut, :string
  end
end
