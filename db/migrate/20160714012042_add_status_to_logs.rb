class AddStatusToLogs < ActiveRecord::Migration
  def change
    add_column :logs, :status, :boolean
  end
end
