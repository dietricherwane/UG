class SportcashController < ApplicationController


  def list_bets
    url = Parameter.first.gateway_url + "/ail/sportcash/ussd/064582ec8/gamer/bets/list/#{session[:msisdn]}"
    bets = RestClient.get(url) rescue nil

    GenericLog.create(operation: "List SPORTCASH bets", request_log: url, response_log: bets)

    bets = JSON.parse(bets) rescue nil
    bets = bets["bets"] rescue nil

    unless bets.blank?
      @bets = Kaminari.paginate_array(bets).page(params[:page])
    end
  end
end
