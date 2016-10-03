class AddCodeAndTotalTimeToMtnStartSessionLogs < ActiveRecord::Migration
  def change
    add_column :mtn_start_session_logs, :request_code, :string
    add_column :mtn_start_session_logs, :total_time, :string
    add_column :mtn_start_session_logs, :request_headers, :text
  end
end
