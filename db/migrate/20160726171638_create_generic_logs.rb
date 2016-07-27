class CreateGenericLogs < ActiveRecord::Migration
  def change
    create_table :generic_logs do |t|
      t.text :operation
      t.text :request_log
      t.text :response_log

      t.timestamps
    end
  end
end
