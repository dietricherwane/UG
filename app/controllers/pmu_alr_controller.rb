class PmuAlrController < ApplicationController

  def index
    session[:full_box] = 'FALSE'
    url = Parameter.first.parionsdirect_url + "/ussd_pmu/get_alr_current_program"
    session_data = RestClient.get(url) rescue nil

    GenericLog.create(operation: "PMU ALR get session data", request_log: url, response_log: session_data)

    session_data = JSON.parse(session_data) rescue nil
    session[:alr_program_id] = session_data["program_id"]
    session[:alr_program_date] = session_data["program_date"]
    session[:alr_program_status] = session_data["status"]
    session[:alr_race_ids] = session_data["race_ids"].split('-') rescue []
    session[:alr_base] = nil
    session[:alr_selection] = nil

    url = Parameter.first.parionsdirect_url + "/ussd_pmu/get_alr_race_list"
    race_data = RestClient.get(url) rescue nil

    GenericLog.create(operation: "PMU ALR get races data", request_log: url, response_log: race_data)

    race_data = JSON.parse(race_data) rescue nil
    session[:race_data] = race_data["alr_race_list"] rescue nil

    if session[:alr_program_status] != 'ON' || session[:alr_race_ids].length == 0 || session[:race_data].blank?
      flash[:error] = "Il n'y a aucun programme disponible"
      redirect_to list_games_path
    end
  end

  def bet_type
    @national = params[:national]

    session[:alr_national] = "Nationale #{@national[-1, 1]}"
    session[:alr_national_index] = @national[-1, 1]
  end

  def generic_formula_selection
    @bet_type = params[:bet_type]
    session[:alr_multi_type] = nil

    set_bet_type
  end

  def multi_formula_selection
    session[:alr_bet_type] = 'Multi'
    session[:alr_bet_type_code] = '13'
  end

  def validate_multi_formula_selection
    session[:alr_multi_type] = params[:multi_type]

    render :select_horses
  end

  def set_bet_type
    case @bet_type
      when 'couple_place'
        session[:alr_bet_type] = 'Couplé placé'
        session[:alr_bet_type_code] = '4'
      when 'couple_gagnant'
        session[:alr_bet_type] = 'Couplé gagnant'
        session[:alr_bet_type_code] = '2'
      when 'tierce'
        session[:alr_bet_type] = 'Tiercé'
        session[:alr_bet_type_code] = '7'
      when 'quarte'
        session[:alr_bet_type] = 'Quarté'
        session[:alr_bet_type_code] = '8'
      when 'quinte'
        session[:alr_bet_type] = 'Quinté'
        session[:alr_bet_type_code] = '10'
      when 'quinte_plus'
        session[:alr_bet_type] = 'Quinté +'
        session[:alr_bet_type_code] = '11'
      end
  end

  def select_horses
    @formula = params[:alr_formula]

    set_formula
  end

  def full_formula
    @horses_numbers = params[:selection]

    if valid_horses_numbers
      session[:alr_selection] = @horses_numbers.split.join(',')
    else
      flash.now[:error] = "Veuillez entrer des numéros de chevaux valides"
      render :select_horses
    end
  end

  def validate_full_formula
    session[:full_box] = (params[:status] == '1' ? 'TRUE' : 'FALSE')

    render :stake
  end

  def select_base
    @formula = params[:alr_formula]

    set_formula
  end

  def validate_base
    @base_numbers = params[:base]

    if valid_base_numbers
      session[:alr_base] = @base_numbers.split.join(',')
      if session[:raw_alr_formula] == 'champ_reduit'
        redirect_to pmu_alr_select_horses_path(session[:raw_alr_formula])
      else
        if session[:raw_alr_formula] == 'champ_total'
          render :full_formula
        else
          render :stake
        end
      end
    else
      flash.now[:error] = "Veuillez entrer des numéros de chevaux valides"
      render :select_base
    end
  end

  def set_formula
    session[:raw_alr_formula] = @formula
    case @formula
      when 'longchamp'
        session[:alr_formula] = 'Long champ'
      when 'champ_reduit'
        session[:alr_formula] = 'Champ réduit'
      when 'champ_total'
        session[:alr_formula] = 'Champ total'
      end
  end

  def stake
    @horses_numbers = params[:selection]

    if valid_horses_numbers
      session[:alr_selection] = @horses_numbers.split.join(',')
    else
      flash.now[:error] = "Veuillez entrer des numéros de chevaux valides"
      render :select_horses
    end
  end

  def evaluate_bet
    @stake = params[:stake]

    if @stake.blank? || not_a_number?(@stake)
      flash.now[:error] = "Veuillez entrer un nombre de fois valide"
      render :stake
    else
      session[:alr_stake] = @stake
      set_bet_parameters

      url = Parameter.first.gateway_url + "/cm3/api/0cad36b144/game/evaluate/#{@program_id}/#{@race_id}"
      bet = RestClient.get(url) rescue nil
      comma = session[:alr_selection].to_s.blank? ? '' : ','
      items = session[:alr_base].blank? ? '' : (session[:alr_base].to_s + comma + session[:alr_selection].to_s)
      request_body = %Q(
                    {
                      "games":[
                        {
                          "game_id":"1",
                          "bet_id":"#{@bet_id}",
                          "nb_units":"#{@stake}",
                          "full_box":"#{session[:full_box]}",
                          "items":[#{items.gsub(/x/i, %Q/"X"/)}]
                        }
                      ]
                    }
                  )
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
        render :stake
      else
        if json_object["error"].blank?
          status = true
          session[:alr_scratched_list] = json_object["evaluations"]["scratched"]
          session[:alr_combinations] = json_object["evaluations"]["evaluations"].first["nb_combinations"]
          session[:alr_amount] = json_object["evaluations"]["evaluations"].first["amount"]
          flash.now[:success] = %Q[
            Vous vous apprêtez à prendre un pari PMU ALR
            #{session[:alr_national]} - #{session[:alr_bet_type]} - #{session[:alr_formula]}
            #{session[:bet_type_value]} > #{session[:plr_formula_value]}
            Base:
            Sélection: #{session[:alr_selection]}
            Votre pari est estimé à #{session[:alr_amount]} FCFA
          ]
        else
          status = false
          flash.now[:error] = "Code: #{json_object["error"]["code"]} -- Message: #{json_object["error"]["description"]}"
          render :stake
        end
      end

      GenericLog.create(operation: "Evaluate PMU ALR bet", request_log: url + request_body, response_log: body)
    end
  end

  def place_bet
     @paymoney_password = params[:paymoney_account_password]

    if @paymoney_password.to_s.length != 4 || not_a_number?(@paymoney_password)
      flash.now[:error] = "Le format du mot de passe est incorrect. Le code secret doit être de 4 chiffres."
      render :evaluate_bet
    else
      @gamer_id = RestClient.get(Parameter.first.gateway_url + "/8ba869a7a9c59f3a0/api/users/gamer_id/#{session[:msisdn]}") rescue ''
      @paymoney_account_number = session[:paymoney_account_number]
      set_bet_parameters

      url = Parameter.first.gateway_url + "/cm3/api/98d24611fd/ticket/sell/#{@gamer_id}/#{@paymoney_account_number}/#{@paymoney_password}/#{session[:alr_program_date]}/#{session[:alr_program_date]}"
      bet = RestClient.get(url) rescue nil
      comma = session[:alr_selection].to_s.blank? ? '' : ','
      items = session[:alr_base].blank? ? '' : (session[:alr_base].to_s + comma + session[:alr_selection].to_s)
      request_body = %Q(
                    {
                      "program_id":"#{@program_id}",
                      "race_id":"#{@race_id}",
                      "amount":"#{session[:alr_amount]}",
                      "scratched_list":#{session[:alr_scratched_list]},
                      "wagers":[
                        {
                          "bet_id":"#{@bet_id}",
                          "nb_units":"#{session[:alr_stake]}",
                          "nb_combinations":"#{session[:alr_combinations]}",
                          "full_box":"#{session[:full_box]}",
                          "selection":[#{items.gsub(/x/i, %Q/"X"/)}]
                        }
                      ]
                    }
                  )
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
        flash.now[:error] = "Code: 0 -- Message: Le pari n'a pas pu être pris"
        render :evaluate_bet
      else
        if json_object["error"].blank?
          status = true
          flash.now[:success] = %Q[
            Votre ticket a été validé
            #{session[:alr_national]} - #{session[:alr_bet_type]} - #{session[:alr_formula]}
            #{session[:bet_type_value]} > #{session[:plr_formula_value]}
            #{session[:alr_base].blank? ? '' : 'Base: ' + session[:alr_base] + ','}
            Sélection: #{session[:alr_selection]}
            Numéro de ticket: #{json_object["bet"]["serial_number"]}
          ]
          render :index
        else
          status = false
          flash.now[:error] = "Code: #{json_object["error"]["code"]} -- Message: #{json_object["error"]["description"]}"
          render :evaluate_bet
        end
      end

      GenericLog.create(operation: "Place PMU ALR bet", request_log: url + request_body, response_log: body)
    end


  end

  def set_bet_parameters
    @program_id = session[:alr_program_id]
    race_index = session[:alr_national][-1, 1]
    @race_id = session[:alr_race_ids][race_index.to_i - 1]
    @bet_id = session[:alr_bet_type_code]
  end

  def valid_horses_numbers
    status = true

    if @horses_numbers.blank?
      status = false
    else
      @horses_numbers.split.each do |horse_number|
        if not_a_number?(horse_number) && horse_number.upcase != 'X'
          status = false
        end
      end
    end

    return status
  end

  def valid_base_numbers
    status = true

    if @base_numbers.blank?
      status = false
    else
      @base_numbers.split.each do |horse_number|
        if not_a_number?(horse_number) && horse_number.upcase != 'X'
          status = false
        end
      end
    end

    return status
  end

  def list_bets
    url = Parameter.first.gateway_url + "/ail/pmu_alr/ussd/064582ec2/gamer/bets/list/#{session[:msisdn]}"
    bets = RestClient.get(url) rescue nil

    GenericLog.create(operation: "List PMU ALR bets", request_log: url, response_log: bets)

    bets = JSON.parse(bets) rescue nil
    bets = bets["bets"] rescue nil

    unless bets.blank?
      @bets = Kaminari.paginate_array(bets).page(params[:page])
    end
  end
end
