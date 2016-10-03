class CreateMtnStartSessionLogs < ActiveRecord::Migration
  def change
    create_table :mtn_start_session_logs do |t|
      t.text :request_log
      t.text :response_log

      t.timestamps
    end
  end
end
