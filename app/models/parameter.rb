class Parameter < ActiveRecord::Base
  # Accessible fields
  attr_accessible :gateway_url, :paymoney_url, :paymoney_wallet_url, :parionsdirect_url
end
