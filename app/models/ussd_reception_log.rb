class UssdReceptionLog < ActiveRecord::Base
  # Accessible fields
  attr_accessible :received_parameters, :rev_id, :rev_password, :sp_id, :service_id, :timestamp, :trace_unique_id, :msg_type, :sender_cb, :receiver_cb, :ussd_of_type, :msisdn, :service_code, :code_scheme, :ussd_string, :error_code, :error_message, :status, :remote_ip
end
