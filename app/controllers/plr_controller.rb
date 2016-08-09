class PlrController < ApplicationController


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
