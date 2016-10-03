class AddRequestUrlToMtnStartSessionLogs < ActiveRecord::Migration
  def change
    add_column :mtn_start_session_logs, :request_url, :string
  end
end
