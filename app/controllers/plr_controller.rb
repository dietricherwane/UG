class PlrController < ApplicationController

  def index

  end

  def race_selection
    reunion_number = params[:reunion]

    if reunion_number.blank?
      flash.now[:error] = "Veuillez entrer le numéro de réunion"
      render :index
    else
      session[:plr_reunion_number] = reunion_number
    end
  end

  def game_selection
    race_number = params[:plr_race_number]

    if race_number.blank?
      flash.now[:error] = "Veuillez entrer le numéro de course"
      render :race_selection
    else
      session[:plr_race_number] = race_number
    end
  end

  def bet_type

  end

  def select_formula
    session[:bet_type] = params[:bet_type]

    case session[:bet_type]
      when "trio"
        session[:bet_type_value] = "Trio"
      when "jumele_gagnant"
        session[:bet_type_value] = "Jumelé Gagnant"
      when "jumele_place"
        session[:bet_type_value] = "Jumelé Placé"
      when "simple_gagnant"
        session[:bet_type_value] = "Simple Gagnant"
      when "simple_place"
        session[:bet_type_value] = "Simple Placé"
      end

    if ["trio", "jumele_gagnant", "jumele_place"].include?(session[:bet_type])
      session[:menu_index] = 1
    else
      session[:menu_index] = 2
    end
  end

  def races_list
    url = Parameter.first.parionsdirect_url + "/ussd_pmu/get_plr_race_list"
    races = RestClient.get(url) rescue nil

    GenericLog.create(operation: "List PMU PLR races", request_log: url, response_log: races)

    races = JSON.parse(races) rescue nil
    races = races["plr_race_list"] rescue nil

    unless races.blank?
      @races = Kaminari.paginate_array(races).page(params[:page])
    end
  end

  def stake_selection
    @horses_numbers = params[:plr_selection]

    if valid_horses_numbers
      session[:plr_selection] = @horses_numbers.split.join('-')
    else
      flash.now[:error] = 'Veuillez entrer des numéros de chevaux valides'
      render :select_formula
    end
  end

  def base_selection
    @base = params[:plr_base]

    if valid_base
      session[:plr_base] = @base.split.join(',')
    else
      flash.now[:error] = 'Veuillez entrer une base valide'
      render :formula_selection
    end
  end

  def selection
    @base = params[:selection]

    if valid_base
      session[:plr_selection] = @base.split.join(',')
    else
      flash.now[:error] = 'Veuillez entrer une sélection valide'
      render :base_selection
    end
  end

  def total_selection
    @base = params[:plr_base]

    if valid_base
      session[:plr_base] = @base.split.join(',')
      render :stake_selection
    else
      flash.now[:error] = 'Veuillez entrer une base valide'
      render :formula_selection
    end
  end

  def alternative_stake_selection
    @horses_numbers = params[:horses_numbers]

    if valid_horses_numbers
      session[:plr_selection] = @horses_numbers.split.join('-')
    else
      flash.now[:error] = 'Veuillez entrer des numéros de chevaux valides'
      render :formula_selection
    end
  end

  def valid_horses_numbers
    status = true

    if @horses_numbers.blank?
      status = false
    else
      @horses_numbers.split.each do |horse_number|
        if not_a_number?(horse_number)
          status = false
        end
      end
    end

    return status
  end

  def valid_base
    status = true

    if @base.blank? #|| @base.split.length > 2
      status = false
    else
      @base.split.each do |base|
        if not_a_number?(base)
          status = false
        end
      end
    end

    return status
  end

  def bet

  end

  def evaluate_bet
    repeats = params[:plr_stake]

    if repeats.blank? || not_a_number?(repeats)
      flash.now[:error] = "Veuillez entrer une valeur valide"
      render :selection
    else
      session[:repeats] = repeats
      set_bet_code_and_modifier
      url = Parameter.first.gateway_url + "/ail/pmu/api/3c9342cf06/bet/query"
      request_body = %Q[
                    {
                      "bet_code":"#{@bet_code}",
                      "bet_modifier":"#{@bet_modifier}",
                      "selector1":"#{session[:plr_reunion_number]}",
                      "selector2":"#{session[:plr_race_number]}",
                      "repeats":"#{session[:repeats]}",
                      "special_entries":"#{session[:plr_base]}",
                      "normal_entries":"#{session[:plr_selection]}"
                    }
                  ]
      request = Typhoeus::Request.new(
        url,
        method: :post,
        body: request_body
      )
      request.run
      response = request.response
      body = response.body

      json_object = JSON.parse(body) rescue nil
      if json_object.blank?
        flash.now[:error] = "Code: 0 -- Message: Le pari n'a pas pu être évalué"
      else
        if json_object["error"].blank?
          status = true
          flash.now[:success] = %Q[
            Vous vous apprêtez à prendre un pari PMU PLR
            R#{session[:plr_reunion_number]}C#{session[:race_number]}
            #{session[:bet_type_value]} > #{session[:plr_formula_value]}
            Base: #{session[:plr_base]}
            Sélection: #{session[:plr_selection]}
            Votre pari est estimé à #{json_object["bet"]["bet_cost_amount"]} FCFA
          ]
        else
          status = false
          flash.now[:error] = "Code: #{json_object["error"]["code"]} -- Message: #{json_object["error"]["description"]}"
        end
      end

      Log.create(msisdn: session[:msisdn], bet_request: request_body, bet_response: body, status: status)
    end
  end

  def place_bet
    @gamer_id = RestClient.get(Parameter.first.gateway_url + "/8ba869a7a9c59f3a0/api/users/gamer_id/#{session[:msisdn]}") rescue ''
    @paymoney_account_number = session[:paymoney_account_number]
    @paymoney_account_password = params[:paymoney_account_password]
    url = Parameter.first.gateway_url + "/ail/pmu/api/dik749742e/bet/place/#{@gamer_id}/#{@paymoney_account_number}/#{@paymoney_account_password}"
  end

  def set_bet_code_and_modifier
    @bet_code = ''
    @bet_modifier = ''

    if session[:bet_type_value] == 'Simple Gagnant'
      @bet_code = '100'
      @bet_modifier = '0'
    end
    if session[:bet_type_value] == 'Simple Placé'
      @bet_code = '101'
      @bet_modifier = '0'
    end
    if session[:bet_type_value] == 'Jumelé Gagnant'
      case session[:plr_formula_value]
        when 'Long champs'
          @bet_code = '107'
          @bet_modifier = '0'
        when 'Champ réduit'
          @bet_code = '111'
          @bet_modifier = '0'
        when 'Champ total'
          @bet_code = '109'
          @bet_modifier = '0'
        end
    end
    if session[:bet_type_value] == 'Jumelé Placé'
      case session[:plr_formula_value]
        when 'Long champs'
          @bet_code = '108'
          @bet_modifier = '0'
        when 'Champ réduit'
          @bet_code = '112'
          @bet_modifier = '0'
        when 'Champ total'
          @bet_code = '110'
          @bet_modifier = '0'
        end
    end
    if session[:bet_type_value] == 'Trio'
      if session[:plr_formula_value] == 'Long champs'
        @bet_code = '102'
        @bet_modifier = '0'
      end
      if session[:plr_formula_value] == 'Champ réduit'
        if session[:plr_base].split(',').length == 1
          @bet_code = '104'
          @bet_modifier = '0'
        else
          @bet_code = '106'
          @bet_modifier = '0'
        end
      end
      if session[:plr_formula_value] == 'Champ total'
        if session[:plr_base].split(',').length == 1
          @bet_code = '103'
          @bet_modifier = '0'
        else
          @bet_code = '105'
          @bet_modifier = '0'
        end
      end
    end
  end

  def formula_selection
    session[:plr_formula] = params[:formula]
    session[:plr_base] = ''
    session[:plr_selection] = ''

    case session[:plr_formula]
      when "longchamp"
        session[:plr_formula_value] = "Long champs"
      when "champ_reduit"
        session[:plr_formula_value] = "Champ réduit"
      when "champ_total"
        session[:plr_formula_value] = "Champ total"
      end

    #session[:menu_index] = 2
  end

  def list_bets
    url = Parameter.first.gateway_url + "/ail/pmu/ussd/064582ec4/gamer/bets/list/#{session[:msisdn]}"
    bets = RestClient.get(url) rescue nil

    GenericLog.create(operation: "List PMU PLR bets", request_log: url, response_log: bets)

    bets = JSON.parse(bets) rescue nil
    bets = bets["bets"] rescue nil

    unless bets.blank?
      @bets = Kaminari.paginate_array(bets).page(params[:page])
    end
  end
end
