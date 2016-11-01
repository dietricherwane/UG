class AddAlrHorsesFieldsToUssdSessions < ActiveRecord::Migration
  def change
    add_column :ussd_sessions, :alr_base, :string
    add_column :ussd_sessions, :alr_selection, :string
    add_column :ussd_sessions, :full_formula_boolean, :string
  end
end
