class AddStatusToMtnStartSessionLogs < ActiveRecord::Migration
  def change
    add_column :mtn_start_session_logs, :status, :boolean
  end
end
