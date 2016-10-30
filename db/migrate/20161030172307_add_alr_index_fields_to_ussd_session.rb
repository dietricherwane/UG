class AddAlrIndexFieldsToUssdSession < ActiveRecord::Migration
  def change
    add_column :ussd_sessions, :alr_full_box, :string
    add_column :ussd_sessions, :alr_get_current_program_request, :text
    add_column :ussd_sessions, :alr_get_current_program_response, :text
    add_column :ussd_sessions, :alr_program_id, :string
    add_column :ussd_sessions, :alr_program_date, :string
    add_column :ussd_sessions, :alr_program_status, :string
    add_column :ussd_sessions, :alr_race_ids, :string
    add_column :ussd_sessions, :alr_race_list_request, :text
    add_column :ussd_sessions, :alr_race_list_response, :text
  end
end
