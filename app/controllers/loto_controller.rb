class LotoController < ApplicationController

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

  def select_bet
    session[:numbers] = params[:numbers]
    session[:stake] = params[:stake]
    session[:selection] = params[:selection]

    if numbers_overflow || invalid_numbers_range
      render :bet
    else
      set_repeats

      if @repeats.to_i > 100000 || @repeats.to_i < 100
        flash.now[:error] = "VOTRE PARI EST ESTIME A: #{@repeats}. LE MONTANT DE VOTRE PARI DOIT ETRE COMPRIS ENTRE 100 F ET 100 000 F CFA !"
        render :bet
      else
        flash.now[:success] = "VOUS VOUS APPRETEZ A PRENDRE UN PARI: #{session[:bet] == '1N' ? 'PN' : session[:bet]} #{session[:formula]} Montant débité: #{@repeats} F CFA. Confirmez en saisissant votre code secret PAYMONEY."
      end
    end
  end

  def invalid_numbers_range
    status = false
    numbers = session[:numbers].split rescue []

    numbers.each do |number|
      if number.to_i < 1 || number.to_i > 90
        status = true
      end
    end

    numbers = session[:selection].split rescue []

    numbers.each do |number|
      if number.to_i < 1 || number.to_i > 90
        status = true
      end
    end

    if status
      flash.now[:error] = "Veuillez choisir des numéros compris entre 1 et 90  pour parier."
    end

    return status
  end

  def numbers_overflow
    status = false
    # Simple
    if session[:formula] == 'Simple' && (session[:selection].split.length rescue 0) != session[:bet].gsub('N', '').to_i
      status = true
      flash.now[:error] = "Vous devez sélectionner #{session[:bet].gsub('N', '').to_i} numéros"
    end
    # Perm
    if session[:formula] == 'Perm' && ((session[:selection].split.length rescue 0) > 10 || (session[:selection].split.length rescue 0) < session[:bet].gsub('N', '').to_i + 1)
      status = true
      flash.now[:error] = "Vous devez sélectionner entre #{session[:bet].gsub('N', '').to_i + 1} et 10 numéros"
    end
    # Champ reduit
    if session[:formula] == 'Champ reduit' && (session[:numbers].split.length rescue 0) > (session[:bet].gsub('N', '').to_i - 1)
      status = true
      flash.now[:error] = "Vous devez sélectionner au maximum #{(session[:bet].gsub('N', '').to_i - 1)} numéros"
    end
    # Champ total
    if session[:formula] == 'Champ total' && (session[:numbers].split.length rescue 0) > (session[:bet].gsub('N', '').to_i - 1)
      status = true
      flash.now[:error] = "Vous devez sélectionner au maximum #{(session[:bet].gsub('N', '').to_i - 1)}"
    end

    return status
  end

  def place_bet
    @gamer_id = RestClient.get(Parameter.first.gateway_url + "/8ba869a7a9c59f3a0/api/users/gamer_id/#{session[:msisdn]}") rescue ''
    @paymoney_account_number = session[:paymoney_account_number]
    @paymoney_account_password = params[:paymoney_account_password]
    url = Parameter.first.gateway_url + "/ail/loto/api/96455396dc/bet/place/#{@gamer_id}/#{@paymoney_account_number}/#{@paymoney_account_password}"

    if @paymoney_account_password.to_s.length == 4 && !not_a_number?(@paymoney_account_password)
      #if valid_numbers
        set_request_parameters

        request_body = %Q[
                  {
                    "bet_code":"#{@bet_code}",
                    "bet_modifier":"0",
                    "selector1":"#{@selector1}",
                    "selector2":"#{@selector2}",
                    "repeats":"#{session[:stake]}",
                    "special_entries":"#{@numbers.join(',')}",
                    "normal_entries":"#{@selection.join(',')}",
                    "draw_day":"",
                    "draw_number":"",
                    "begin_date":"#{@begin_date}",
                    "end_date":"#{@end_date}",
                    "basis_amount":"#{session[:stake]}"
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
          flash.now[:error] = "Code: 0 -- Message: Le pari n'a pas pu être pris"
        else
          if json_object["error"].blank?
            status = true
            flash.now[:success] = %Q[
              Loto Bonheur – #{session[:formula]} - « FELICITATIONS, votre pari a bien été  enregistré. N° ticket : #{json_object["bet"]["ticket_number"]} / Réf. : #{json_object["bet"]["ref_number"]}
Consultez les résultats le #{@end_date}.
            ]
          else
            status = false
            flash.now[:error] = "Code: #{json_object["error"]["code"]} -- Message: #{json_object["error"]["description"]} -- #{request_body}"
          end
        end

        Log.create(msisdn: session[:msisdn], gamer_id: @gamer_id, paymoney_account_number: @paymoney_account_number, paymoney_password: @paymoney_account_password, drawing: session[:drawing], bet: session[:bet], formula: session[:formula], bet_request: request_body, bet_response: body, status: status)
      #end
    else
      flash.now[:error] = "Le format du mot de passe est incorrect. Le code secret doit être de 4 chiffres."
    end

    render :select_bet
  end

  def valid_bet_params
    @status = true
    if @gamer_id.blank?
      flash.now[:error] = "Le compte parieur n'a pas été trouvé"
      @status = false
    else
      # Vérification de l'existence des numéros de compte, mot de passe, numéros pariés et mise (existence et numéricité)
      if @paymoney_account_number.blank? || @paymoney_account_password.blank? || session[:numbers].blank? || session[:stake].blank? || not_a_number?(session[:stake])
        flash.now[:error] = "Veuillez renseigner le numéro de compte paymoney, le mot de passe, les numéros pariés et une mise valide"
        @status = false
      end
    end

    return @status
  end

  def valid_numbers
    @status = true
    @numbers = session[:numbers].split rescue nil
    if @numbers.blank?
      flash.now[:error] = "Veuillez renseigner des numéros à miser"
      @status = false
    else
      # Vérification de la cohérence du nombre de numéros pariés
      #if (session[:bet] == '1N' && @numbers.length != 1) || (session[:bet] == '2N' && @numbers.length != 2) || (session[:bet] == '3N' && @numbers.length != 3) || (session[:bet] == '4N' && @numbers.length != 4) || (session[:bet] == '5N' && @numbers.length != 5)
        # Vérification de la numéricité des numéros pariés
      @numbers.each do |number|
        if not_a_number?(number)
          flash.now[:error] = "Veuillez miser uniquement des numéros"
          @status = false
        end

      end

      if session[:formula] == 'Champ reduit'
        @selection = session[:selection].split rescue nil
        if @selection.blank?
          flash.now[:error] = "Veuillez renseigner la sélection"
          @status = false
        else
          @selection.each do |selection|
            if not_a_number?(selection)
              flash.now[:error] = "Veuillez sélectionner uniquement des numéros"
              @status = false
            end
          end
        end
      end
    end



    return @status
  end

  def set_request_parameters
    set_bet_code
    set_selector1
    set_selector2
    set_begin_and_end_date
    set_repeats
  end

  def set_bet_code
    @bet_code = ''
    case session[:bet]
      when '1N'
        @bet_code = '229'
      when '2N'
        @bet_code = '231'
      when '3N'
        @bet_code = '232'
      when '4N'
        @bet_code = '233'
      when '5N'
        @bet_code = '234'
      end
  end

  def set_selector1
    @selector1 = ''
    case session[:drawing]
      when 'Etoile'
        @selector1 = '1'
      when 'Emergence'
        @selector1 = '5'
      when 'Fortune'
        @selector1 = '2'
      when 'Privilege'
        @selector1 = '6'
      when 'Solution'
        @selector1 = '3'
      when 'Diamant'
        @selector1 = '4'
      end
  end

  def set_selector2
    @selector2 = ''
    case session[:drawing]
      when 'Etoile'
        @selector2 = -16 + DateTime.parse("01/01/#{Date.today.year} 17:00:00").upto(DateTime.now).count(&:monday?)
      when 'Emergence'
        @selector2 = -16 + DateTime.parse("01/01/#{Date.today.year} 17:00:00").upto(DateTime.now).count(&:tuesday?)
      when 'Fortune'
        @selector2 = -8 + DateTime.parse("01/01/#{Date.today.year} 17:00:00").upto(DateTime.now).count(&:wednesday?)
      when 'Privilege'
        @selector2 = -16 + DateTime.parse("01/01/#{Date.today.year} 17:00:00").upto(DateTime.now).count(&:thursday?)
      when 'Solution'
        @selector2 = -17 + DateTime.parse("01/01/#{Date.today.year} 17:00:00").upto(DateTime.now).count(&:friday?)
      when 'Diamant'
        @selector2 = -8 + DateTime.parse("01/01/#{Date.today.year} 17:00:00").upto(DateTime.now).count(&:saturday?)
      end
  end

  def set_begin_and_end_date
    @begin_date = ''
    @end_date = ''
    case session[:drawing]
      when 'Etoile'
        @begin_date = Date.commercial(Date.today.year, Date.today.cwday.modulo(4)+Date.today.cweek, 1).strftime("%d-%m-%Y 17:00:00")
        @end_date = Date.commercial(Date.today.year, 1 + Date.today.cweek, 1).strftime("%d-%m-%Y 17:00:00")
      when 'Emergence'
        @begin_date = Date.commercial(Date.today.year, Date.today.cwday.modulo(4)+Date.today.cweek, 2).strftime("%d-%m-%Y 17:00:00")
        @end_date = Date.commercial(Date.today.year, 1 + Date.today.cweek, 2).strftime("%d-%m-%Y 17:00:00")
      when 'Fortune'
        @begin_date = Date.commercial(Date.today.year, Date.today.cwday.modulo(4)+Date.today.cweek, 3).strftime("%d-%m-%Y 17:00:00")
        @end_date = Date.commercial(Date.today.year, 1 + Date.today.cweek, 3).strftime("%d-%m-%Y 17:00:00")
      when 'Privilege'
        @begin_date = Date.commercial(Date.today.year, Date.today.cwday.modulo(4)+Date.today.cweek, 4).strftime("%d-%m-%Y 17:00:00")
        @end_date = Date.commercial(Date.today.year, 1 + Date.today.cweek, 4).strftime("%d-%m-%Y 17:00:00")
      when 'Solution'
        @begin_date = Date.commercial(Date.today.year, Date.today.cwday.modulo(4)+Date.today.cweek, 5).strftime("%d-%m-%Y 17:00:00")
        @end_date = Date.commercial(Date.today.year, 1 + Date.today.cweek, 5).strftime("%d-%m-%Y 17:00:00")
      when 'Diamant'
        @begin_date = Date.commercial(Date.today.year, Date.today.cwday.modulo(4)+Date.today.cweek, 6).strftime("%d-%m-%Y 17:00:00")
        @end_date = Date.commercial(Date.today.year, 1 + Date.today.cweek, 6).strftime("%d-%m-%Y 17:00:00")
      end
  end

  def set_repeats
    @repeats = ''
    @numbers = session[:numbers].split rescue [] # base
    @selection = session[:selection].split rescue [] # selection

    if session[:bet] != '1N'
      case session[:formula]
        when 'Simple'
          @repeats = session[:stake].to_i
        when 'Perm'
          @repeats = @selection.combination(session[:bet].sub('n', '').to_i).count * session[:stake].to_i
        when 'Champ reduit'
          #@repeats = @selection.count * session[:stake].to_i
          @repeats = @selection.combination(session[:bet].sub('n', '').to_i - @numbers.count).count * session[:stake].to_i
        when 'Champ total'
          @repeats = Array.new(90 - @numbers.count).combination(session[:bet].sub('n', '').to_i - @numbers.count).count * session[:stake].to_i
      end
    else
      @repeats = session[:stake].to_i
    end
    #@repeats = (session[:stake].to_i / 25).to_i
=begin
    if session[:formula] = 'Simple'
      @repeats = (@basis_amount.to_i / 25).to_i
    end
    if session[:formula] = 'Perm'
      @repeats = (@basis_amount.to_i / 25).to_i
    end
=end
  end

  def list_bets
    url = Parameter.first.gateway_url + "/ail/loto/ussd/064482ec4/gamer/bets/list/#{session[:msisdn]}"
    bets = RestClient.get(url) rescue nil

    GenericLog.create(operation: "List Loto bets", request_log: url, response_log: bets)

    bets = JSON.parse(bets) rescue nil
    bets = bets["bets"] rescue nil

    unless bets.blank?
      @bets = Kaminari.paginate_array(bets).page(params[:page])
    end
  end

end
