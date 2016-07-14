class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  def not_a_phone_number?(n)
  	(n.to_s.match(/\A[+-]?\d+?(\.\d+)?\Z/) == nil || n.to_s.length != 8) ? true : false
  end

  def not_a_number?(n)
  	n.to_s.match(/\A[+-]?\d+?(\.\d+)?\Z/) == nil ? true : false
  end
end
