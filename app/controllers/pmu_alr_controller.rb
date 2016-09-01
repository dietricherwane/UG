class PmuAlrController < ApplicationController

  def index
    url = Parameter.first.parionsdirect_url + "/ussd_pmu/get_alr_current_program"
    session_data = RestClient.get(url) rescue nil

    GenericLog.create(operation: "PMU ALR get session data", request_log: url, response_log: session_data)

    session_data = JSON.parse(session_data) rescue nil
    session[:alr_program_id] = session_data["program_id"]
    session[:alr_program_date] = session_data["program_date"]
    session[:alr_program_status] = session_data["program_status"]
    session[:alr_race_ids] = session_data["race_ids"].split('-') rescue []

    if session[:alr_program_status] != 'ON' || session[:alr_race_ids].length == 0
      flash[:error] = "Il n'y a aucun programme disponible"
      redirect_to list_games_path
    end
  end

  def bet_type
    @national = params[:national]

    set_national
  end

  def set_national
    case @national
      when 'national1'
        session[:alr_national] = 'Nationale 1'
      when 'national2'
        session[:alr_national] = 'Nationale 2'
      when 'national3'
        session[:alr_national] = 'Nationale 3'
      end
  end

  def generic_formula_selection
    @bet_type = params[:bet_type]

    set_bet_type
  end

  def multi_formula_selection
    @bet_type = params[:bet_type]
    session[:alr_bet_type] = 'Multi'
  end

  def set_bet_type
    case @bet_type
      when 'couple_place'
        session[:alr_bet_type] = 'Couplé placé'
      when 'couple_gagnant'
        session[:alr_bet_type] = 'Couplé gagnant'
      when 'tierce'
        session[:alr_bet_type] = 'Tiercé'
      when 'quarte'
        session[:alr_bet_type] = 'Quarté'
      when 'quinte'
        session[:alr_bet_type] = 'Quinté'
      when 'quinte_plus'
        session[:alr_bet_type] = 'Quinté +'
      end
  end

  def select_horses
    @formula = params[:alr_formula]

    set_formula
  end

  def set_formula
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
    @horses_numbers = params[:horses]

    if valid_horses_numbers
      session[:alr_horses] = params[:horses].split.join(',')
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
