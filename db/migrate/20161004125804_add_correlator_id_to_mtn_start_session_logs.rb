class AddCorrelatorIdToMtnStartSessionLogs < ActiveRecord::Migration
  def change
    add_column :mtn_start_session_logs, :correlator_id, :string
  end
end
