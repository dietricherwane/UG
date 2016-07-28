class HomeController < ApplicationController

  def get_msisdn

  end

  def index
    session[:msisdn] = params[:msisdn]
    if not_a_phone_number?(params[:msisdn])
      flash.now[:error] = "Veuillez entrer un numéro de téléphone valide"
      render :get_msisdn
    else
      url = Parameter.first.gateway_url + "/85fg69a7a9c59f3a0/api/users/password/#{session[:msisdn]}"
      password_salt = RestClient.get(url) rescue ''

      GenericLog.create(operation: "Check user existence", request_log: url, response_log: password_salt)

      password_salt = password_salt.split('-') rescue ''
      password = password_salt[0]
      salt = password_salt[1]
      # The phone number does not exists in the database so Parionsdirect account should be created
      if password.blank?
        render :new_parionsdirect_account
      else
      # The phone number exists so the holder should authenticate
        session[:password] = password
        session[:salt] = salt
        render :parionsdirect_authentication_form
      end
    end
  end

  def main_menu

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
      url = Parameter.first.gateway_url + "/6ba041bf35229938ba869a7a9c59f3a0/api/users/account/create/1/1/#{@pseudo}/#{@firstname}/#{@lastname}/#{@email}/#{@password}/#{@password_confirmation}/#{session[:msisdn]}/#{@birthdate}/d2a29d336c48fe68df6e5827cc49a042"

      parionsdirect_account = RestClient.get(url) rescue nil
      GenericLog.create(operation: "Create parionsdirect account", request_log: url, response_log: parionsdirect_account)
      parionsdirect_account = JSON.parse(parionsdirect_account) rescue nil

      if parionsdirect_account.blank?
        flash.now[:error] = "Une erreur s'est produite"
      else
        if parionsdirect_account["errors"].blank?
          flash.now[:success] = "Votre compte a été correctement créé. Veuillez l'activer via le lien reçu par email"
        else
          flash.now[:error] = parionsdirect_account["errors"].first["message"] rescue nil
        end
      end
    else
      flash.now[:error] = 'Veuillez renseigner tous les paramètres.'
    end

    if flash.now[:error].blank?
      render :new_paymoney_account
    else
      render :new_parionsdirect_account
    end
  end

  # Check parionsdirect creation parameters
  def valid_parionsdirect_account_params?
    status = true
    if @pseudo.blank? || @firstname.blank? || @lastname.blank? || @email.blank? || @password.blank? || @password_confirmation.blank? || @birthdate.blank?
      status = false
    end

    return status
  end

  def set_paymoney_account

  end

  def validate_paymoney_account
    paymoney_account_number = params[:paymoney_account_number]
    if paymoney_account_number.blank?
      flash.now[:error] = "Veuillez renseigner un numéro de compte"
      render :set_paymoney_account
    else
      url = Parameter.first.paymoney_url + "/PAYMONEY_WALLET/rest/check2_compte/#{paymoney_account_number}"
      paymoney_token = RestClient.get(url) rescue nil

      GenericLog.create(operation: "Check paymoney account existence with account number", request_log: url, response_log: paymoney_token)

      if !paymoney_token.blank? && paymoney_token != 'null'
        render :main_menu
      else
        flash.now[:error] = "Le numéro de compte Paymoney n'est pas valide"
        render :set_paymoney_account
      end
    end
    # http://94.247.178.141:8080/rest/check4_compte/58908957
  end

  # If the gamer does not have a paymoney account, it should be created
  def create_paymoney_account
    url = ""
    paymoney_account = RestClient.get(url) rescue nil

    render :set_paymoney_account
  end

  def parionsdirect_authentication_form

  end

  def authenticate_parionsdirect_account
    password = Digest::SHA2.hexdigest(session[:salt] + params[:password])

    if password == session[:password]
      url = Parameter.first.paymoney_url + "/rest/check4_compte/#{session[:msisdn]}"
      paymoney_account = RestClient.get(url) rescue nil

      GenericLog.create(operation: "Check paymoney account existence with msisdn", request_log: url, response_log: paymoney_account)

      # If paymoney account exists
      if !paymoney_account.blank? && paymoney_account != 'null'
        session[:paymoney_account_number] = paymoney_account
        render :main_menu
      else
        render :set_paymoney_account
      end
    else
      flash.now[:error] = "Le mot de passe n'est pas valide"
      render :parionsdirect_authentication_form
    end
  end

  def list_games

  end

end
