class HomeController < ApplicationController

  def get_msisdn

  end

  def index
    session[:msisdn] = params[:msisdn]
    if not_a_phone_number?(params[:msisdn])
      flash.now[:error] = "Veuillez entrer un numéro de téléphone valide"
      #render :get_msisdn
    else
      password = RestClient.get(Parameter.first.gateway_url + "/85fg69a7a9c59f3a0/api/users/password/#{session[:msisdn]}") rescue ''
      # The phone number does not exists in the database so Parionsdirect account should be created
      if password.blank?
        render :new_parionsdirect_account
      else
      # The phone number exists so the holder should authenticate
        session[:password] = password
        render :parionsdirect_authentication_form
      end
    end
  end

  def new_parionsdirect_account

  end

  def create_parionsdirect_account

  end

  def parionsdirect_authentication_form

  end

  def list_games

  end

end
