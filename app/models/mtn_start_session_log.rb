class MtnStartSessionLog < ActiveRecord::Base
  # Accessible fields
  attr_accessible :request_url, :request_log, :response_log, :request_code, :total_time, :request_headers, :error_code, :error_message, :status, :correlator_id, :operation_type, :time_trail
end
