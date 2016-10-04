class AddReceivedParametersToUssdReceptionLogs < ActiveRecord::Migration
  def change
    add_column :ussd_reception_logs, :received_parameters, :text
  end
end
