class LotoController < ApplicationController

  # Selectors 2
  @@etoile_selecto2 = '198'
  @@fortune_selector2 = '204'
  @@solution_selector2 = '198'
  @@diamond_selector2 = '205'

  def index

  end

  def bet_selection
    session[:drawing] = params[:drawing]
  end

  def formula_selection
    session[:bet] = params[:bet]
  end

  def bet
    session[:formula] = params[:formula]
  end

end
