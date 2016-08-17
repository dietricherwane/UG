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

  def stake_selection
    @horses_numbers = params[:horses_numbers]

    if valid_horses_numbers
      session[:horses_numbers] = @horses_numbers.split
    else
      flash.now[:error] = "Veuillez entrer des numéros de chevaux valides"
      render :select_formula
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

  def bet

  end

  def formula_selection
    session[:plr_formula] = params[:formula]

    case session[:plr_formula]
      when "longchamp"
        session[:plr_formula_value] = "Long champs"
      when "champ_reduit"
        session[:plr_formula_value] = "Champ réduit"
      when "champ_total"
        session[:plr_formula_value] = "Champ total"
      end

    session[:menu_index] = 2

    render :select_formula
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
