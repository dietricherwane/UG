class UssdSession < ActiveRecord::Base
  attr_accessible :session_identifier, :sender_cb, :parionsdirect_password_url, :parionsdirect_password_response, :parionsdirect_password, :parionsdirect_salt, :creation_pd_password, :creation_pd_password_confirmation, :creation_pd_request, :creation_pd_response, :creation_pw_request, :creation_pw_response, :pd_account_created, :pw_account_created, :connection_pd_pasword
end
