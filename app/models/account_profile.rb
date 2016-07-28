class AccountProfile < ActiveRecord::Base
  # Accessible fields
  attr_accessible :msisdn, :paymoney_account_number
end
