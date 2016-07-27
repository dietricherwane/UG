class GenericLog < ActiveRecord::Base
  # Accessible fields
  attr_accessible :operation, :request_log, :response_log
end
