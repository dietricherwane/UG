class AddPlrHorsesFieldsToUssdSessions < ActiveRecord::Migration
  def change
    add_column :ussd_sessions, :plr_formula_label, :string
    add_column :ussd_sessions, :plr_formula_shortcut, :string
    add_column :ussd_sessions, :plr_base, :string
    add_column :ussd_sessions, :plr_selection, :string
    add_column :ussd_sessions, :plr_number_of_times, :string
  end
end
