class Log < ActiveRecord::Base
  # Accessible fields
  attr_accessible :msisdn, :gamer_id, :paymoney_account_number, :paymoney_password, :bet_request, :bet_response, :status, :drawing, :bet, :formula
end
