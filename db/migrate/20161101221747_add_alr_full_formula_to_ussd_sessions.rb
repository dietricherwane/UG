class AddAlrFullFormulaToUssdSessions < ActiveRecord::Migration
  def change
    add_column :ussd_sessions, :full_formula, :boolean
  end
end
