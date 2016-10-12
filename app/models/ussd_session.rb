class UssdSession < ActiveRecord::Base
  attr_accessible :session_identifier, :sender_cb, :parionsdirect_password_url, :parionsdirect_password_response, :parionsdirect_password, :parionsdirect_salt
end
