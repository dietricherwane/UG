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
    race_number = params[:race_number]

    if race_number.blank?
      flash.now[:error] = "Veuillez entrer le numéro de course"
      render :race_selection
    else
      session[:race_number] = race_number
    end
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
