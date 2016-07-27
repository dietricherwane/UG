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
    @pseudo = params[:pseudo]
    @firstname = params[:firstname]
    @lastname = params[:lastname]
    @email = params[:email]
    @password = params[:password]
    @password_confirmation = params[:password_confirmation]
    @birthdate = params[:birthdate]

    if valid_parionsdirect_account_params?
      url = Parameter.first.gateway_url + "/6ba041bf35229938ba869a7a9c59f3a0/api/users/account/create/1/1/#{@pseudo}/#{@firstname}/#{@lastname}/#{@email}/#{@password}/#{@password_confirmation}/#{session[:msisdn]}/birthdate/2"

      parionsdirect_account = RestClient.get(url) rescue nil

      GenericLog.create(operation: "Create parionsdirect account", request_log: url, response_log: parionsdirect_account)

      parionsdirect_account = JSON.parse(parionsdirect_account) rescue nil

      flash.now[:error] = parionsdirect_account.to_s
    else
      flash.now[:error] = 'Veuillez renseigner tous les paramètres.'
    end

    render :new_parionsdirect_account
  end

  # Check parionsdirect creation parameters
  def valid_parionsdirect_account_params?
    status = true
    if @pseudo.blank? || @firstname.blank? || @lastname.blank? || @email.blank? || @password.blank? || @password_confirmation.blank? || @birthdate.blank?
      status = false
    end

    return status
  end

  def parionsdirect_authentication_form

  end

  def list_games

  end

end
