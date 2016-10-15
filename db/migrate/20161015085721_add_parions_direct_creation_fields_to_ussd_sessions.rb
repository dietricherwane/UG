class AddParionsDirectCreationFieldsToUssdSessions < ActiveRecord::Migration
  def change
    add_column :ussd_sessions, :creation_pd_password, :string
    add_column :ussd_sessions, :creation_pd_password_confirmation, :string
    add_column :ussd_sessions, :creation_pd_request, :text
    add_column :ussd_sessions, :creation_pd_response, :text
    add_column :ussd_sessions, :creation_pw_request, :text
    add_column :ussd_sessions, :creation_pw_response, :text
  end
end
