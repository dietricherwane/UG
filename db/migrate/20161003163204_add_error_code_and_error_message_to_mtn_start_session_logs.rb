class AddErrorCodeAndErrorMessageToMtnStartSessionLogs < ActiveRecord::Migration
  def change
    add_column :mtn_start_session_logs, :error_code, :string
    add_column :mtn_start_session_logs, :error_message, :text
  end
end
