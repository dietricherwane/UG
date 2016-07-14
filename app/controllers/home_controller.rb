class HomeController < ApplicationController

  def get_msisdn

  end

  def index
    if not_a_phone_number?(params[:msisdn])
      flash.now[:error] = "Veuillez entrer un numéro de téléphone valide"
      render :get_msisdn
    else
      session[:msisdn] = params[:msisdn]
    end
  end

  def list_games

  end

end
