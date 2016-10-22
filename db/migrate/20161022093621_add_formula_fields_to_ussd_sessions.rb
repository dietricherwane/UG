class AddFormulaFieldsToUssdSessions < ActiveRecord::Migration
  def change
    add_column :ussd_sessions, :formula_label, :string
    add_column :ussd_sessions, :formula_shortcut, :string
  end
end
