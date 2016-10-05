class AddFieldsToUssdReceptionLogs < ActiveRecord::Migration
  def change
    add_column :ussd_reception_logs, :rev_id, :string
    add_column :ussd_reception_logs, :rev_password, :string
    add_column :ussd_reception_logs, :sp_id, :string
    add_column :ussd_reception_logs, :service_id, :string
    add_column :ussd_reception_logs, :timestamp, :string
    add_column :ussd_reception_logs, :trace_unique_id, :string
    add_column :ussd_reception_logs, :msg_type, :string
    add_column :ussd_reception_logs, :sender_cb, :string
    add_column :ussd_reception_logs, :receiver_cb, :string
    add_column :ussd_reception_logs, :ussd_of_type, :string
    add_column :ussd_reception_logs, :msisdn, :string
    add_column :ussd_reception_logs, :service_code, :string
    add_column :ussd_reception_logs, :code_scheme, :string
    add_column :ussd_reception_logs, :ussd_string, :string
    add_column :ussd_reception_logs, :error_code, :string
    add_column :ussd_reception_logs, :error_message, :string
    add_column :ussd_reception_logs, :status, :boolean
    add_column :ussd_reception_logs, :remote_ip, :string
  end
end
