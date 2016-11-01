class AddAlrEvalFieldsToUssdSessions < ActiveRecord::Migration
  def change
    add_column :ussd_sessions, :alr_scratched_list, :string
    add_column :ussd_sessions, :alr_combinations, :string
    add_column :ussd_sessions, :alr_amount, :string
  end
end
