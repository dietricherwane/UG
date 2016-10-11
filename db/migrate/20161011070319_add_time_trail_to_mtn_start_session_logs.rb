class AddTimeTrailToMtnStartSessionLogs < ActiveRecord::Migration
  def change
    add_column :mtn_start_session_logs, :time_trail, :text
  end
end
