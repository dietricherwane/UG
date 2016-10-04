class AddOperationTypeToMtnStartSessionLogs < ActiveRecord::Migration
  def change
    add_column :mtn_start_session_logs, :operation_type, :string
  end
end
