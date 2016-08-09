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

  def paymoney_balance

  end

  def get_paymoney_balance
    password = params[:password]

    if password.blank?
      flash.now[:error] = "Veuillez entrer un mot de passe"
    else
      url = Parameter.first.paymoney_url + "/PAYMONEY_WALLET/rest/solte_compte/#{session[:paymoney_account_number]}/#{password}"
      balance = RestClient.get(url) rescue nil

      GenericLog.create(operation: "Paymoney balance", request_log: url, response_log: balance)

      balance = JSON.parse(balance)["solde"] rescue nil

      if balance.blank?
        flash.now[:error] = "Le mot de passe saisi n'est pas valide"
      else
        flash.now[:success] = "Votre solde est de: #{balance rescue 0} FCFA"
      end
    end

    render :paymoney_balance
  end

  def other_account_paymoney_balance

  end

  def get_other_paymoney_balance
    paymoney_account_number = params[:paymoney_account_number]
    password = params[:password]

    if paymoney_account_number.blank? || password.blank?
      flash.now[:error] = "Veuillez renseigner tous les champs"
    else
      url = Parameter.first.paymoney_url + "/PAYMONEY_WALLET/rest/solte_compte/#{paymoney_account_number}/#{password}"
      balance = RestClient.get(url) rescue nil

      GenericLog.create(operation: "Other account Paymoney balance", request_log: url, response_log: balance)

      balance = JSON.parse(balance)["solde"] rescue nil

      if balance.blank?
        flash.now[:error] = "Veuillez vérifier le numéro de compte et le mot de passe"
      else
        flash.now[:success] = "Votre solde est de: #{balance rescue 0} FCFA"
      end
    end

    render :other_account_paymoney_balance
  end

  def saved_paymoney_account

  end

  def update_saved_paymoney_account
    paymoney_account = params[:paymoney_account]

    if paymoney_account.blank?
      flash.now[:error] = "Veuillez entrer un numéro de compte Paymoney associé au compte"
    else
      url = Parameter.first.paymoney_url + "/PAYMONEY_WALLET/rest/check2_compte/#{paymoney_account}"
      paymoney_token = RestClient.get(url) rescue nil

      GenericLog.create(operation: "Check paymoney account saved paymoney account", request_log: url, response_log: paymoney_token)

      if !paymoney_token.blank? && paymoney_token != 'null'
        session[:paymoney_account_number] = paymoney_account

        # Link msisdn to paymoney account
        AccountProfile.find_by_msisdn(session[:msisdn]).update_attributes(paymoney_account_number: paymoney_account)
        flash.now[:success] = "Votre compte Paymoney associé a été mis à jour"
      else
        flash.now[:error] = "Le compte Paymoney saisi n'est pas valide"
      end
    end

    render :saved_paymoney_account
  end

  def new_parionsdirect_account

  end

  def create_parionsdirect_account
    @pseudo = 'parionsdirect'
    @firstname = 'Parionsdirect'
    @lastname = 'Parionsdirect'
    @email = 'parions@direct.ci'
    @password = params[:password]
    @password_confirmation = params[:password_confirmation]
    @birthdate = '12-12-1900'

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
        session[:paymoney_account_number] = paymoney_account_number

        # Link msisdn to paymoney account
        AccountProfile.create(msisdn: session[:msisdn], paymoney_account_number: paymoney_account_number)

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

    flash.now[:error] = "Le compte Paymoney n'a pas pu être créé"

    render :set_paymoney_account
  end

  def parionsdirect_authentication_form

  end

  def authenticate_parionsdirect_account
    password = Digest::SHA2.hexdigest(session[:salt] + params[:password])

    if password == session[:password]
      #url = Parameter.first.paymoney_url + "/rest/check4_compte/#{session[:msisdn]}"
      #paymoney_account = RestClient.get(url) rescue nil
      paymoney_account = AccountProfile.find_by_msisdn(session[:msisdn]).paymoney_account_number rescue nil

      #GenericLog.create(operation: "Check paymoney account existence with msisdn", request_log: url, response_log: paymoney_account)

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

  def list_games_bets

  end

  def list_otp
    url = Parameter.first.paymoney_wallet_url + "/api/4c4556c239/otp/#{session[:paymoney_account_number]}"
    otps = RestClient.get(url) rescue nil

    GenericLog.create(operation: "List OTP", request_log: url, response_log: otps)

    otps = JSON.parse(otps)["otps"] rescue nil

    unless otps.blank?
      @otps = Kaminari.paginate_array(otps).page(params[:page])
    end
  end

end
