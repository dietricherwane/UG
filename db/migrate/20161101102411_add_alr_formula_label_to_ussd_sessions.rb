class AddAlrFormulaLabelToUssdSessions < ActiveRecord::Migration
  def change
    add_column :ussd_sessions, :alr_formula_label, :string
    add_column :ussd_sessions, :alr_formula_shortcut, :string
  end
end
