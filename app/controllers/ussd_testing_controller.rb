class UssdTestingController < ApplicationController
  #after_filter :send_ussd, :only => :main_menu

  #soap_service namespace: 'Ussd:MTN:wsdl'

=begin
  def start_session
    client = Savon.client do
      endpoint "http://196.201.33.108:8310/USSDNotificationManagerService/services/USSDNotificationManager"
      namespace "http://www.csapi.org/wsdl/osg/ussd/notification_manager/v1_0/"
    end

    render text: client.operations.to_s
  end
=end

  def start_session
    url = '196.201.33.108:8310/USSDNotificationManagerService/services/USSDNotificationManager'
    sp_id = '2250110000460'
    service_id = '225012000003070'
    password = 'bmeB500'
    timestamp = DateTime.now.strftime('%Y%m%d%H%M%S')
    sp_password = Digest::MD5.hexdigest(sp_id + password + timestamp)
    endpoint_url = 'http://195.14.0.128:6564/mtn/ussd/main_menu'
    #endpoint_url = 'http://41.189.40.193:6564/ussd_testing/wsdl'
    #endpoint_url = '154.68.45.82:1183/ussd_testing/wsdl'
    correlator_id = Digest::SHA1.hexdigest([DateTime.now.iso8601(6), rand].join).hex.to_s[0..8]
    shortcode = '*218'
    interface_name = 'MainMenu'

    request_body = %Q[
      <soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:loc="http://www.csapi.org/schema/osg/ussd/notification_manager/v1_0/local">
        <soapenv:Header>
          <tns:RequestSOAPHeader xmlns:tns="http://www.huawei.com.cn/schema/common/v2_1">
          <tns:spId>#{sp_id}</tns:spId>
          <tns:spPassword>#{sp_password}</tns:spPassword>
          <tns:serviceId>#{service_id}</tns:serviceId>
          <tns:timeStamp>#{timestamp}</tns:timeStamp>
          </tns:RequestSOAPHeader>
        </soapenv:Header>
        <soapenv:Body>
          <loc:startUSSDNotification>
          <loc:reference>
            <endpoint>#{endpoint_url}</endpoint>
            <interfaceName>#{interface_name}</interfaceName>
            <correlator>#{correlator_id}</correlator>
          </loc:reference>
          <loc:ussdServiceActivationNumber>#{shortcode}</loc:ussdServiceActivationNumber>
          </loc:startUSSDNotification>
        </soapenv:Body>
      </soapenv:Envelope>
    ]

    start_session_response = Typhoeus.post(url, body: request_body, connecttimeout: 30)

    nokogiri_response = (Nokogiri.XML(start_session_response.body) rescue nil)

    error_code = nokogiri_response.xpath('//soapenv:Fault').at('faultcode').content rescue nil
    error_message = nokogiri_response.xpath('//soapenv:Fault').at('faultstring').content rescue nil

    if error_code.blank?
      status = true
      Correlator.first.update_attributes(correlator_id: correlator_id) || Correlator.create(correlator_id: correlator_id)
    else
      status = false
    end

    MtnStartSessionLog.create(operation_type: "Start session", request_url: url, request_log: request_body, response_log: start_session_response.body, request_code: start_session_response.code, total_time: start_session_response.total_time, request_headers: start_session_response.headers.to_s, error_code: error_code, error_message: error_message, status: status, correlator_id: correlator_id)

    render text: start_session_response.body
  end

  def stop_session
    url = '196.201.33.108:8310/USSDNotificationManagerService/services/USSDNotificationManager'
    sp_id = '2250110000460'
    service_id = '225012000003070'
    password = 'bmeB500'
    timestamp = DateTime.now.strftime('%Y%m%d%H%M%S')
    sp_password = Digest::MD5.hexdigest(sp_id + password + timestamp)
    endpoint_url = 'http://195.14.0.128:6564/mtn/ussd/main_menu'
    #endpoint_url = 'http://41.189.40.193:6564/ussd_testing/wsdl'
    #endpoint_url = 'http://41.189.40.193:6564/ussd_testing/wsdl'
    correlator_id = Correlator.first.correlator_id
    shortcode = '*218'
    interface_name = 'MainMenu'

    request_body = %Q[
      <soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:loc="http://www.csapi.org/schema/osg/ussd/notification_manager/v1_0/local">
        <soapenv:Header>
          <tns:RequestSOAPHeader xmlns:tns="http://www.huawei.com.cn/schema/common/v2_1">
            <tns:spId>#{sp_id}</tns:spId>
            <tns:spPassword>#{sp_password}</tns:spPassword>
            <tns:serviceId>#{service_id}</tns:serviceId>
            <tns:timeStamp>#{timestamp}</tns:timeStamp>
          </tns:RequestSOAPHeader>
        </soapenv:Header>
        <soapenv:Body>
          <loc:stopUSSDNotification>
            <loc:correlator>#{correlator_id}</loc:correlator>
          </loc:stopUSSDNotification>
        </soapenv:Body>
      </soapenv:Envelope>
    ]

    stop_session_response = Typhoeus.post(url, body: request_body, connecttimeout: 30)

    nokogiri_response = (Nokogiri.XML(stop_session_response.body) rescue nil)

    error_code = nokogiri_response.xpath('//soapenv:Fault').at('faultcode').content rescue nil
    error_message = nokogiri_response.xpath('//soapenv:Fault').at('faultstring').content rescue nil

    if error_code.blank?
      status = true
      Correlator.first.update_attributes(correlator_id: nil)
    else
      status = false
    end

    MtnStartSessionLog.create(operation_type: "Stop session", request_url: url, request_log: request_body, response_log: stop_session_response.body, request_code: stop_session_response.code, total_time: stop_session_response.total_time, request_headers: stop_session_response.headers.to_s, error_code: error_code, error_message: error_message, status: status)

    render text: stop_session_response.body
  end

  def main_menu
    @raw_body = request.body.read.gsub("ns1:", "").gsub("ns2:", "") rescue nil
    @received_body = (Nokogiri.XML(@raw_body) rescue nil)
    remote_ip_address = request.remote_ip
    @error_code = '0'
    @error_message = ''

    c_main_menu_parse_xml

    if @error_code == '0'
      # Découpage des paramètres reçus dans la requête et attribution à des variables
      main_menu_parse_xml

      # Contrôles sur les paramètres transmis
      c_main_menu_check_sp_id
      c_main_menu_check_service_id
      c_main_menu_check_unique_id
      c_main_menu_check_msg_type
      c_main_menu_check_sender_cb
      c_main_menu_check_receive_cb
      c_main_menu_check_ussd_op_type
      c_main_menu_check_msisdn
      c_main_menu_check_service_code
      c_main_menu_check_ussd_string

      # Détermination du type de message à transmettre (sendussd ou abort response)
      c_main_menu_abort_message?(@abort_reason)
    end

    # Responds to the SDP depending on the message type (sendussd or abort response)
    set_main_menu_result_text(@abort_reason, @error_code)

    UssdReceptionLog.create(received_parameters: @raw_body, rev_id: @rev_id, rev_password: @rev_password, sp_id: @sp_id, service_id: @service_id, timestamp: @timestamp, trace_unique_id: @unique_id, msg_type: @msg_type, sender_cb: @sender_cb, receiver_cb: @receive_cb, ussd_of_type: @ussd_op_type, msisdn: @msisdn, service_code: @service_code, code_scheme: @code_scheme, ussd_string: @ussd_string, error_code: @error_code, error_message: @error_message, remote_ip: remote_ip_address)

    render :xml => @result

    Thread.new do
      if @error_code == '0'
        # Récupération d'une session existante
        @current_ussd_session = UssdSession.find_by_sender_cb(@sender_cb)

        if @current_ussd_session.blank?
          authenticate_or_create_parionsdirect_account(@msisdn)
          UssdSession.create(session_identifier: @session_identifier, sender_cb: @sender_cb, parionsdirect_password_url: @parionsdirect_password_url, parionsdirect_password_response: (@parionsdirect_password_response.body rescue 'ERR'), parionsdirect_password: @password, parionsdirect_salt: @salt)
        else
          case @current_ussd_session.session_identifier
          # Saisie du mot de passe de création de compte parionsdirect
          when '1'
            set_parionsdirect_password
            @current_ussd_session.update_attributes(session_identifier: @session_identifier, creation_pd_password: @creation_pd_password)
          # Saisie de la confirmation du mot de passe de création de compte parionsdirect
          when '3'
            create_parionsdirect_account
            @current_ussd_session.update_attributes(session_identifier: @session_identifier, creation_pd_password_confirmation: @creation_pd_password_confirmation, creation_pd_request: @creation_pd_request, creation_pd_response: (@creation_pd_response.body rescue 'ERR'), pd_account_created: @pd_account_created)
          when '2'
            check_parionsdirect_password
            @current_ussd_session.update_attributes(session_identifier: @session_identifier, connection_pd_pasword: @ussd_string)
          when '4'
            check_paymoney_account_number
            @current_ussd_session.update_attributes(session_identifier: @session_identifier, check_pw_account_url: @check_pw_account_url, check_pw_account_response: (@check_pw_account_response.body rescue 'ERR'), pw_account_number: @pw_account_number, pw_account_token: @pw_account_token)
          # Saisie du numéro de compte PAYMONEY
          when '4-'
            create_paymoney_account
            @current_ussd_session.update_attributes(session_identifier: @session_identifier, creation_pw_request: @creation_pw_request, creation_pw_response: (@creation_pw_response.body rescue 'ERR'), pw_account_created: @pw_account_created)
           # Sélection d'un élément du menu
          when '8'
            # solde du compte paymoney
            get_paymoney_sold
            @current_ussd_session.update_attributes(session_identifier: @session_identifier, paymoney_sold_url: @get_paymoney_sold_url, paymoney_sold_response: (@get_paymoney_sold_response.body rescue nil))
          when '9'
            # affichage de la liste des otp
            get_paymoney_otp
            @current_ussd_session.update_attributes(session_identifier: @session_identifier, paymoney_otp_url: @get_paymoney_otp_url, paymoney_otp_response: (@get_paymoney_otp_response.body rescue nil))
          when '10'
            # retour au menu principal ou affichage des otp d'un autre compte
            list_otp_set_session_identifier
            @current_ussd_session.update_attributes(session_identifier: @session_identifier)
          when '5'
            set_session_identifier_depending_on_menu_selected
            if @status
              case @ussd_string
                when '1'
                  display_games_menu
                  @current_ussd_session.update_attributes(session_identifier: @session_identifier)
                when '2'

                when '3'
                  get_paymoney_password_to_check_sold
                  @current_ussd_session.update_attributes(session_identifier: @session_identifier)
                when '4'

                when '5'

                when '6'
                  get_paymoney_password_to_check_otp
                  @current_ussd_session.update_attributes(session_identifier: @session_identifier)
                when '7'

              end
            end
          # Affichage du menu listant les jeux
          when '11'
            set_session_identifier_depending_on_game_selected
            if @status
              case @ussd_string
                when '1'
                  loto_display_draw_day
                  @current_ussd_session.update_attributes(session_identifier: @session_identifier)
                when '2'
                  alr_display_races
                  @current_ussd_session.update_attributes(session_identifier: @session_identifier, alr_get_current_program_request: @alr_get_current_program_request, alr_get_current_program_response: @alr_get_current_program_response.body, alr_program_id: @alr_program_id, alr_program_date: @alr_program_date, alr_program_status: @alr_program_status, alr_race_ids: @alr_race_ids.to_s, alr_race_list_request: @alr_race_list_request, alr_race_list_response: @alr_race_list_response.body, race_data: @race_data.to_s)
                when '3'
                  plr_get_reunion
                  @current_ussd_session.update_attributes(session_identifier: @session_identifier)
                when '4'

              end
            end
          # Choix du jour de tirage
          when '12'
            set_session_identifier_depending_on_draw_day_selected
            if @status
              reference_date = "01/01/#{Date.today.year} 19:00:00"
              case @ussd_string
                when '1'
                  @draw_day_label = "Etoile #{(-16 + DateTime.parse(reference_date).upto(DateTime.now).count(&:monday?)).to_s}"
                  @draw_day_shortcut = 'etoile'
                when '2'
                  @draw_day_label = "Emergence #{(-16 + DateTime.parse(reference_date).upto(DateTime.now).count(&:tuesday?)).to_s}"
                  @draw_day_shortcut = 'emergence'
                when '3'
                  @draw_day_label = "Fortune #{(-8 + DateTime.parse(reference_date).upto(DateTime.now).count(&:wednesday?)).to_s}"
                  @draw_day_shortcut = 'fortune'
                when '4'
                  @draw_day_label = "Privilège #{(-16 + DateTime.parse(reference_date).upto(DateTime.now).count(&:thursday?)).to_s}"
                  @draw_day_shortcut = 'privilege'
                when '5'
                  @draw_day_label = "Solution #{(-17 + DateTime.parse(reference_date).upto(DateTime.now).count(&:friday?)).to_s}"
                  @draw_day_shortcut = 'solution'
                when '6'
                  @draw_day_label = "Diamant #{(-8 + DateTime.parse(reference_date).upto(DateTime.now).count(&:saturday?)).to_s}"
                  @draw_day_shortcut = 'diamant'
              end
              loto_display_bet_selection
              @current_ussd_session.update_attributes(session_identifier: @session_identifier, draw_day_label: @draw_day_label, draw_day_shortcut: @draw_day_shortcut)
            end
          # Choix de la sélection
          when '13'
            set_session_identifier_depending_on_bet_selection_selected
            if @status
              case @ussd_string
                when '1'
                  @bet_selection = "PN"
                  @bet_selection_shortcut = 'pn'
                when '2'
                  @bet_selection = "2N"
                  @bet_selection_shortcut = '2n'
                when '3'
                  @bet_selection = "3N"
                  @bet_selection_shortcut = '3n'
                when '4'
                  @bet_selection = "4N"
                  @bet_selection_shortcut = '4n'
                when '5'
                  @bet_selection = "5N"
                  @bet_selection_shortcut = '5n'
              end
              loto_display_formula_selection
              @current_ussd_session.update_attributes(session_identifier: @session_identifier, bet_selection: @bet_selection, bet_selection_shortcut: @bet_selection_shortcut)
            end
          when '14'
            set_session_identifier_depending_on_formula_selected
            if @status
              case @ussd_string
                when '1'
                  @formula_label = "Simple"
                  @formula_shortcut = 'simple'
                when '2'
                  @formula_label = "Perm"
                  @formula_shortcut = 'perm'
                when '3'
                  @formula_label = "Champ réduit"
                  @formula_shortcut = 'champ_reduit'
                when '4'
                  @formula_label = "Champ total"
                  @formula_shortcut = 'champ_total'
              end
              loto_display_horse_selection_fields
              @current_ussd_session.update_attributes(session_identifier: @session_identifier, formula_label: @formula_label, formula_shortcut: @formula_shortcut)
            end
          # Saisie de la base au loto
          when '15'
            # Vérification des numéros de base saisis et de leur tranche
            loto_check_base_numbers
            @current_ussd_session.update_attributes(session_identifier: @session_identifier, base_field: @ussd_string)
          when '16'
            # Vérification des numéros de sélection saisis et de leur tranche
            loto_check_selection_numbers
            @current_ussd_session.update_attributes(session_identifier: @session_identifier, selection_field: @selection_field)
          when '17'
            # Saisie de la mise de base et affichage de l'évaluation du pari
            loto_evaluate_bet
            @current_ussd_session.update_attributes(session_identifier: @session_identifier, stake: @ussd_string + '-' + @repeats.to_s)
          when '18'
            # Prise du pari à la saisie du mot de passe Paymoney
            @account_profile = AccountProfile.find_by_msisdn(@msisdn[-8,8])
            loto_place_bet
            @current_ussd_session.update_attributes(session_identifier: @session_identifier, loto_bet_paymoney_password: @ussd_string, loto_place_bet_url: @loto_place_bet_url + @request_body, loto_place_bet_response: @loto_place_bet_response.body, get_gamer_id_request: @get_gamer_id_request, get_gamer_id_response: @get_gamer_id_response.body)
          when '20'
            # Vérification du numéro de réunion entré et sélection de la course
            plr_get_race
            @current_ussd_session.update_attributes(session_identifier: @session_identifier, get_plr_race_list_request: @get_plr_race_list_request, get_plr_race_list_response: @get_plr_race_list_response, plr_reunion_number: @ussd_string)
          when '21'
            # Vérification du numéro de course entré
            plr_game_selection
            @current_ussd_session.update_attributes(session_identifier: @session_identifier, plr_race_number: @ussd_string)
          when '22'
            set_session_identifier_depending_on_plr_game_selection
            if @status
              case @ussd_string
                when '1'
                  # Affichage des types de paris
                  display_plr_bet_type
                  @current_ussd_session.update_attributes(session_identifier: @session_identifier)
                when '2'
                  # Affichage des détails de course
                  display_plr_race_details
                  @current_ussd_session.update_attributes(session_identifier: @session_identifier, plr_race_details_request: @plr_race_details_request, plr_race_details_response: @plr_race_details_response)
              end
            end
          when '23'
            set_session_identifier_depending_on_plr_bet_type_selected
            if @status
              case @ussd_string
                when '1'
                  @plr_bet_type_label = 'Trio'
                  @plr_bet_type_shortcut = 'trio'
                  plr_display_plr_formula
                when '2'
                  @plr_bet_type_label = "Jumelé gagnant"
                  @plr_bet_type_shortcut = 'jumele_gagnant'
                  plr_display_plr_formula
                when '3'
                  @plr_bet_type_label = "Jumelé placé"
                  @plr_bet_type_shortcut = 'jumele_place'
                  plr_display_plr_formula
                when '4'
                  @plr_bet_type_label = "Simple gagnant"
                  @plr_bet_type_shortcut = 'simple_gagnant'
                  plr_display_plr_selection
                when '5'
                  @plr_bet_type_label = "Simple placé"
                  @plr_bet_type_shortcut = 'simple_place'
                  plr_display_plr_selection
              end
              @current_ussd_session.update_attributes(session_identifier: @session_identifier, plr_bet_type_label: @plr_bet_type_label, plr_bet_type_shortcut: @plr_bet_type_shortcut)
            end
          when '24'
            set_session_identifier_depending_on_plr_formula_selected
            if @status
              case @ussd_string
                when '1'
                  @plr_formula_label = 'Long champs'
                  @plr_formula_shortcut = 'long_champs'
                  plr_display_plr_selection
                when '2'
                  @plr_formula_label = 'Champ réduit'
                  @plr_formula_shortcut = 'champ_reduit'
                  plr_display_plr_base
                when '3'
                  @plr_formula_label = 'Champ total'
                  @plr_formula_shortcut = 'champ_total'
                  plr_display_plr_base
              end
            end
            @current_ussd_session.update_attributes(session_identifier: @session_identifier, plr_formula_label: @plr_formula_label, plr_formula_shortcut: @plr_formula_shortcut)
          when '25'
            plr_selection_or_stake_depending_on_formula
            @current_ussd_session.update_attributes(session_identifier: @session_identifier, plr_base: @ussd_string)
          # PLR, sélectionner le nombre de fois
          when '26'
            plr_select_number_of_times
            @current_ussd_session.update_attributes(session_identifier: @session_identifier, plr_selection: @ussd_string)
          when '27'
            plr_evaluate_bet
            @current_ussd_session.update_attributes(session_identifier: @session_identifier, plr_number_of_times: @ussd_string, plr_evaluate_bet_request: @plr_evaluate_bet_request + @request_body, plr_evaluate_bet_response: @plr_evaluate_bet_response, bet_cost_amount: @bet_cost_amount)
          when '28'
            @account_profile = AccountProfile.find_by_msisdn(@msisdn[-8,8])
            plr_place_bet
            @current_ussd_session.update_attributes(session_identifier: @session_identifier, plr_number_of_times: @plr_number_of_times, plr_place_bet_request: @plr_place_bet_request + @body, plr_place_bet_response: @plr_place_bet_response.body)
          when '30'
            alr_display_bet_type
            @current_ussd_session.update_attributes(session_identifier: @session_identifier, national_label: @national_label, national_shortcut: @national_shortcut, alr_bet_type_menu: @alr_bet_type_menu)
          when '31'
            alr_display_formula
            @current_ussd_session.update_attributes(session_identifier: @session_identifier, alr_bet_type_label: @bet_type_label, alr_bet_id: @alr_bet_id)
          when '32'
            set_session_identifier_depending_on_alr_bet_type_selected
            if @status
              case @ussd_string
                when '1'
                  alr_select_horses
                  alr_formula_label = 'Long champs'
                  alr_formula_shortcut = 'longchamps'
                when '2'
                  alr_select_base
                  alr_formula_label = 'Champ réduit'
                  alr_formula_shortcut = 'champ_reduit'
                when '3'
                  alr_select_base
                  alr_formula_label = 'Champ total'
                  alr_formula_shortcut = 'champ_total'
              end
            end
            @current_ussd_session.update_attributes(session_identifier: @session_identifier, alr_formula_label: alr_formula_label, alr_formula_shortcut: alr_formula_shortcut)
          when '33'
            set_session_identifier_depending_on_alr_multi_selected
            if @status
              case @ussd_string
                when '1'
                  alr_select_horses
                  alr_formula_label = 'Multi 4/4'
                  alr_formula_shortcut = ' 4/4'
                when '2'
                  alr_select_horses
                  alr_formula_label = 'Multi 4/5'
                  alr_formula_shortcut = ' 4/5'
                when '3'
                  alr_select_horses
                  alr_formula_label = 'Multi 4/6'
                  alr_formula_shortcut = ' 4/6'
                when '4'
                  alr_select_horses
                  alr_formula_label = 'Multi 4/7'
                  alr_formula_shortcut = ' 4/7'
              end
            end
            @current_ussd_session.update_attributes(session_identifier: @session_identifier, alr_formula_label: alr_formula_label, alr_formula_shortcut: alr_formula_shortcut)
          when '34'
            validate_alr_base
            @current_ussd_session.update_attributes(session_identifier: @session_identifier, alr_base: @ussd_string)
          when '35'
            validate_alr_horses
            @current_ussd_session.update_attributes(session_identifier: @session_identifier, alr_selection: @ussd_string)
          when '36'
            alr_set_full_formula
            @current_ussd_session.update_attributes(session_identifier: @session_identifier, full_formula: @full_formula)
          when '37'
            alr_evaluate_bet
            @current_ussd_session.update_attributes(session_identifier: @session_identifier, alr_stake: @alr_stake, alr_evaluate_bet_request: @alr_evaluate_bet_request + @body, alr_evaluate_bet_response: @alr_evaluate_bet_response.body, alr_scratched_list: @alr_scratched_list, alr_combinations: @alr_combinations, alr_amount: @alr_amount)
          when '38'
            @account_profile = AccountProfile.find_by_msisdn(@msisdn[-8,8])
            alr_place_bet
            @current_ussd_session.update_attributes(session_identifier: @session_identifier, alr_place_bet_request: @alr_place_bet_request + @body, alr_place_bet_response: @alr_place_bet_response.body, get_gamer_id_request: @get_gamer_id_request, get_gamer_id_response: @get_gamer_id_response)
          end
        end

        send_ussd(@operation_type, @msisdn, @sender_cb, @linkid, @rendered_text)
      end
    end

    #render text: @rendered_text
  end

  def set_session_identifier_depending_on_menu_selected
    @status = false
    if ['1', '2', '3', '4', '5', '6', '7'].include?(@ussd_string)
      @status = true
    else
      @rendered_text = %Q[
1- Jeux
2- Mes paris
3- Mon solde
4- Rechargement
5- Votre service SMS
6- Mes OTP
7- Mes comptes]
      @session_identifier = '5'
    end
  end

  def set_session_identifier_depending_on_draw_day_selected
    @status = false
    if ['1', '2', '3', '4', '5', '6'].include?(@ussd_string)
      @status = true
    else
      reference_date = "01/01/#{Date.today.year} 19:00:00"
      @rendered_text = %Q[
1- Etoile #{(-16 + DateTime.parse(reference_date).upto(DateTime.now).count(&:monday?)).to_s}
2- Emergence #{(-16 + DateTime.parse(reference_date).upto(DateTime.now).count(&:tuesday?)).to_s}
3- Fortune #{(-8 + DateTime.parse(reference_date).upto(DateTime.now).count(&:wednesday?)).to_s}
4- Privilège #{(-16 + DateTime.parse(reference_date).upto(DateTime.now).count(&:thursday?)).to_s}
5- Solution #{(-17 + DateTime.parse(reference_date).upto(DateTime.now).count(&:friday?)).to_s}
6- Diamant #{(-8 + DateTime.parse(reference_date).upto(DateTime.now).count(&:saturday?)).to_s}]
      @session_identifier = '12'
    end
  end

  def set_session_identifier_depending_on_bet_selection_selected
    @status = false
    if ['1', '2', '3', '4', '5'].include?(@ussd_string)
      @status = true
    else
      @rendered_text = %Q[#{@current_ussd_session.draw_day_label}

1- PN - 1 numéro
2- 2N - 2 numéro
3- 3N - 3 numéro
4- 4N - 4 numéro
5- 5N - 5 numéro]
      @session_identifier = '13'
    end
  end

  def set_session_identifier_depending_on_formula_selected
    @status = false
    if ['1', '2', '3', '4'].include?(@ussd_string)
      @status = true
    else
      @rendered_text = %Q[Loto bonheur - #{@current_ussd_session.bet_selection}
Choisissez votre formule

1- Simple
2- Perm]
      if @bet_selection != 'PN'
        @rendered_text << %Q[
3- Champ réduit
4- Champ total]
      end
      @session_identifier = '14'
    end
  end

  def loto_display_bet_selection
    @rendered_text = %Q[#{@draw_day_label}

1- PN - 1 numéro
2- 2N - 2 numéro
3- 3N - 3 numéro
4- 4N - 4 numéro
5- 5N - 5 numéro]
    @session_identifier = '13'
  end

  def loto_display_formula_selection
    @rendered_text = %Q[Loto bonheur - #{@bet_selection}
Choisissez votre formule

1- Simple
2- Perm]
    if @bet_selection != 'PN'
      @rendered_text << %Q[
3- Champ réduit
4- Champ total]
    end
    @session_identifier = '14'
  end

  def loto_display_horse_selection_fields
    base_required = false
    @rendered_text = %Q[Loto bonheur - #{@current_ussd_session.draw_day_label} #{@current_ussd_session.bet_selection} #{@formula_label}
#{@current_ussd_session.bet_selection == 'PN' ? 'Saisissez votre numéro' : "Saisissez vos numéros séparés d'un espace"} (Entre 1 et 90)
]
    if @formula_label != 'Simple' && @formula_label != 'Perm'
      base_required = true
      @rendered_text << 'Veuillez entrer votre base.'
      @session_identifier = '15'
    end
    if base_required == false
      if @formula_label != 'Champ total'
        @rendered_text << 'Veuillez entrer votre sélection.'
        @session_identifier = '16'
      end
    end
  end

  def loto_check_base_numbers
    @current_ussd_session = @current_ussd_session
    @ussd_string = @ussd_string
    if base_numbers_overflow || invalid_base_numbers_range
      @rendered_text = %Q[#{@error_message}
Loto bonheur - #{@current_ussd_session.draw_day_label} #{@current_ussd_session.bet_selection} #{@formula_label}
#{@current_ussd_session.bet_selection == 'PN' ? 'Saisissez votre numéro' : "Saisissez vos numéros séparés d'un espace"} (Entre 1 et 90)

Veuillez entrer votre base.
]
      @session_identifier = '15'
    else
      if @current_ussd_session.formula_label != 'Champ total'
        @rendered_text = %Q[Loto bonheur - #{@current_ussd_session.draw_day_label} #{@current_ussd_session.bet_selection} #{@formula_label}
Base: #{@ussd_string}
#{@current_ussd_session.bet_selection == 'PN' ? 'Saisissez votre numéro' : "Saisissez vos numéros séparés d'un espace"} (Entre 1 et 90)

Veuillez entrer votre sélection.
]
        @session_identifier = '16'
      else
        @rendered_text = %Q[Loto bonheur - #{@current_ussd_session.draw_day_label} #{@current_ussd_session.bet_selection} #{@formula_label}
Base: #{@ussd_string}
#{@current_ussd_session.bet_selection == 'PN' ? 'Saisissez votre numéro' : "Saisissez vos numéros séparés d'un espace"} (Entre 1 et 90)

Veuillez entrer votre mise de base.
]
        @session_identifier = '17'
      end
    end
  end

  def loto_check_selection_numbers
    @current_ussd_session = @current_ussd_session
    @ussd_string = @ussd_string
    if selection_numbers_overflow || invalid_selection_numbers_range
      @rendered_text = %Q[#{@error_message}
Loto bonheur - #{@current_ussd_session.draw_day_label} #{@current_ussd_session.bet_selection} #{@current_ussd_session.formula_label}
#{!@current_ussd_session.base_field.blank? ? "Base: " + @current_ussd_session.base_field : ""}
#{@current_ussd_session.bet_selection == 'PN' ? 'Saisissez votre numéro' : "Saisissez vos numéros séparés d'un espace"} (Entre 1 et 90)

Veuillez entrer votre sélection.
]
      @session_identifier = '16'
    else
      @rendered_text = %Q[Loto bonheur - #{@current_ussd_session.draw_day_label} #{@current_ussd_session.bet_selection} #{@current_ussd_session.formula_label}
#{!@current_ussd_session.base_field.blank? ? "Base: " + @current_ussd_session.base_field : ""}
Sélection: #{@ussd_string}

Veuillez entrer votre mise de base.
]
      @selection_field = @ussd_string
      @session_identifier = '17'
    end
  end

  def loto_evaluate_bet
    @current_ussd_session = @current_ussd_session
    @ussd_string = @ussd_string
    if @ussd_string.blank? || not_a_number?(@ussd_string)
      @rendered_text = %Q[Veuillez entrer une mise de base valide
Loto bonheur - #{@current_ussd_session.draw_day_label} #{@current_ussd_session.bet_selection} #{@current_ussd_session.formula_label}
#{!@current_ussd_session.base_field.blank? ? "Base: " + @current_ussd_session.base_field : ""}
#{!@current_ussd_session.selection_field.blank? ? "Sélection: " + @current_ussd_session.selection_field : ""}

Veuillez entrer votre mise de base.]
      @session_identifier = '17'
    else
      set_repeats
      @repeats = @repeats
      if @repeats > 100000 || @repeats < 100
        @rendered_text = %Q[Votre pari est estimé à: #{@repeats} FCFA. Le montant de votre pari doit être compris entre 100 et 100 000 FCFA.
Loto bonheur - #{@current_ussd_session.draw_day_label} #{@current_ussd_session.bet_selection} #{@current_ussd_session.formula_label}
#{!@current_ussd_session.base_field.blank? ? "Base: " + @current_ussd_session.base_field : ""}
#{!@current_ussd_session.selection_field.blank? ? "Sélection: " + @current_ussd_session.selection_field : ""}

Veuillez entrer votre mise de base.]
        @session_identifier = '17'
      else
        @rendered_text = %Q[Vous vous appretez à prendre un pari: #{@current_ussd_session.draw_day_label} #{@current_ussd_session.bet_selection} #{@current_ussd_session.formula_label}
#{!@current_ussd_session.base_field.blank? ? "Base: " + @current_ussd_session.base_field : ""}
#{!@current_ussd_session.selection_field.blank? ? "Sélection: " + @current_ussd_session.selection_field : ""}
Montant débité: #{@repeats} FCFA. Confirmez en saisissant votre code secret PAYMONEY.]
        @session_identifier = '18'
      end
    end
  end

  def loto_place_bet
    @current_ussd_session = @current_ussd_session
    if @ussd_string.length != 4 || not_a_number?(@ussd_string)
      @rendered_text = %Q[Veuillez entrer un code PAYMONEY valide
Vous vous appretez à prendre un pari: #{@current_ussd_session.draw_day_label} #{@current_ussd_session.bet_selection} #{@current_ussd_session.formula_label}
#{!@current_ussd_session.base_field.blank? ? "Base: " + @current_ussd_session.base_field : ""}
#{!@current_ussd_session.selection_field.blank? ? "Sélection: " + @current_ussd_session.selection_field : ""}
Montant débité: #{@current_ussd_session.stake.split('-')[1]} FCFA. Confirmez en saisissant votre code secret PAYMONEY.]
      @session_identifier = '18'
    else
      @get_gamer_id_request = Parameter.first.gateway_url + "/8ba869a7a9c59f3a0/api/users/gamer_id/#{@account_profile.msisdn}"
      @get_gamer_id_response = Typhoeus.get(@get_gamer_id_request, connecttimeout: 30)
      if @get_gamer_id_response.body.blank?
        @rendered_text = %Q[Votre identifiant parieur n'a pas pu être récupéré.
Vous vous appretez à prendre un pari: #{@current_ussd_session.draw_day_label} #{@current_ussd_session.bet_selection} #{@current_ussd_session.formula_label}
#{!@current_ussd_session.base_field.blank? ? "Base: " + @current_ussd_session.base_field : ""}
#{!@current_ussd_session.selection_field.blank? ? "Sélection: " + @current_ussd_session.selection_field : ""}
Montant débité: #{@current_ussd_session.stake.split('-')[1]} FCFA. Confirmez en saisissant votre code secret PAYMONEY.]
        @session_identifier = '18'
      else
        @loto_place_bet_url = Parameter.first.gateway_url + "/ail/loto/api/96455396dc/bet/place/#{@get_gamer_id_response.body}/#{@account_profile.paymoney_account_number}/#{@ussd_string}"
        set_place_loto_bet_request_parameters
        @request_body = %Q[
                  {
                    "bet_code":"#{@bet_code}",
                    "bet_modifier":"0",
                    "selector1":"#{@selector1}",
                    "selector2":"#{@selector2}",
                    "repeats":"#{@current_ussd_session.stake.split('-')[0]}",
                    "special_entries":"#{@current_ussd_session.base_field.split().join(',') rescue ''}",
                    "normal_entries":"#{@current_ussd_session.selection_field.split().join(',') rescue ''}",
                    "draw_day":"",
                    "draw_number":"",
                    "begin_date":"#{@begin_date}",
                    "end_date":"#{@end_date}",
                    "basis_amount":"#{@current_ussd_session.stake.split('-')[0]}"
                  }
                ]
        request = Typhoeus::Request.new(
        @loto_place_bet_url,
        method: :post,
        body: @request_body
        )
        request.run
        @loto_place_bet_response = request.response

        json_object = JSON.parse(@loto_place_bet_response.body) rescue nil
        if json_object.blank?
          @rendered_text = %Q[Votre pari n'a pas pu etre placé.
Vous vous appretez à prendre un pari: #{@current_ussd_session.draw_day_label} #{@current_ussd_session.bet_selection} #{@current_ussd_session.formula_label}
#{!@current_ussd_session.base_field.blank? ? "Base: " + @current_ussd_session.base_field : ""}
#{!@current_ussd_session.selection_field.blank? ? "Sélection: " + @current_ussd_session.selection_field : ""}
Montant débité: #{@current_ussd_session.stake.split('-')[1]} FCFA. Confirmez en saisissant votre code secret PAYMONEY.]
          @session_identifier = '18'
        else
          if json_object["error"].blank?
            @rendered_text = %Q[FELICITATIONS, votre pari a bien été  enregistré. N° ticket : #{json_object["bet"]["ticket_number"]} / Réf. : #{json_object["bet"]["ref_number"]}
Consultez les résultats le #{@end_date}]
            @session_identifier = '19'
          else
            @rendered_text = %Q[Votre pari n'a pas pu etre placé.
Vous vous appretez à prendre un pari: #{@current_ussd_session.draw_day_label} #{@current_ussd_session.bet_selection} #{@current_ussd_session.formula_label}
#{!@current_ussd_session.base_field.blank? ? "Base: " + @current_ussd_session.base_field : ""}
#{!@current_ussd_session.selection_field.blank? ? "Sélection: " + @current_ussd_session.selection_field : ""}
Montant débité: #{@current_ussd_session.stake.split('-')[1]} FCFA. Confirmez en saisissant votre code secret PAYMONEY.]
            @session_identifier = '18'
          end
        end
      end
    end
  end

  def set_repeats
    @repeats = 0
    @numbers = @current_ussd_session.base_field.split rescue [] # base
    @selection = @current_ussd_session.selection_field.split rescue [] # selection

    #if @current_ussd_session.bet_selection != 'PN'
    @current_ussd_session.bet_selection == 'PN' ? bet_selection = 1 : bet_selection = @current_ussd_session.bet_selection.sub('N', '').to_i
    case @current_ussd_session.formula_shortcut
      when 'simple'
        @repeats = @ussd_string.to_i
      when 'perm'
        @repeats = @selection.combination(bet_selection).count * @ussd_string.to_i
      when 'champ_reduit'
        @repeats = @selection.combination(bet_selection - @numbers.count).count * @ussd_string.to_i
      when 'champ_total'
        @repeats = Array.new(90 - @numbers.count).combination(bet_selection - @numbers.count).count * @ussd_string.to_i
    end
    #else
      #@repeats = @ussd_string.to_i
    #end
  end

  # Affiche la liste des jeux
  def display_games_menu
    @rendered_text = %Q[
1- Loto Bonheur
2- PMU ALR
3- PMU PLR
4- SPORTCASH]
      @session_identifier = '11'
  end

  def set_session_identifier_depending_on_game_selected
    @status = false
    if ['1', '2', '3', '4'].include?(@ussd_string)
      @status = true
    else
      @rendered_text = %Q[
1- Loto Bonheur
2- PMU ALR
3- PMU PLR
4- SPORTCASH]
      @session_identifier = '11'
    end
  end

  def loto_display_draw_day
    reference_date = "01/01/#{Date.today.year} 19:00:00"
    @rendered_text = %Q[
1- Etoile #{(-16 + DateTime.parse(reference_date).upto(DateTime.now).count(&:monday?)).to_s}
2- Emergence #{(-16 + DateTime.parse(reference_date).upto(DateTime.now).count(&:tuesday?)).to_s}
3- Fortune #{(-8 + DateTime.parse(reference_date).upto(DateTime.now).count(&:wednesday?)).to_s}
4- Privilège #{(-16 + DateTime.parse(reference_date).upto(DateTime.now).count(&:thursday?)).to_s}
5- Solution #{(-17 + DateTime.parse(reference_date).upto(DateTime.now).count(&:friday?)).to_s}
6- Diamant #{(-8 + DateTime.parse(reference_date).upto(DateTime.now).count(&:saturday?)).to_s}]
    @session_identifier = '12'
  end

  def get_paymoney_password_to_check_sold
    @rendered_text = %Q[Veuillez entrer votre mot de passe PAYMONEY pour consulter votre solde.

1- Solde autre compte
    ]
    @session_identifier = '8'
  end

  def get_paymoney_password_to_check_otp
    @rendered_text = %Q[Veuillez entrer votre mot de passe PAYMONEY pour consulter votre liste d'OTP.]
    @session_identifier = '9'
  end

  def get_paymoney_otp
    if @ussd_string.blank?
      @rendered_text = %Q[Veuillez entrer votre mot de passe PAYMONEY pour consulter votre liste d'OTP.]
      @session_identifier = '8'
    else
      account_profile = AccountProfile.find_by_msisdn(@msisdn[-8,8])
      @get_paymoney_otp_url = Parameter.first.paymoney_url + "/PAYMONEY_WALLET/rest/getLastOtp/#{account_profile.paymoney_account_number}/#{@ussd_string}/"
      @get_paymoney_otp_response = Typhoeus.get(@get_paymoney_otp_url, connecttimeout: 30)

      otps = %Q[{"otps":] + (@get_paymoney_otp_response.body rescue nil) + %Q[}]
      otps = JSON.parse(otps)["otps"] rescue nil

      if otps.blank?
        @rendered_text = %Q[
Votre liste d'OTP est vide

1- OTP autre compte
0- Retour
        ]
        @session_identifier = '10'
      else
        otp_string = ""
        otps.each do |otp|
          t = Time.at(((otp["otpDate"].to_s)[0..9]).to_i)
          otp_string << otp["otpPin"] + ' ' + (otp["otpStatus"] == true ? 'Valide' : 'Désactivé') + t.strftime(" %d-%m-%Y ") + t.strftime("%Hh %Mmn") + %Q[
]
        end
        @rendered_text = %Q[
#{otp_string}
1- OTP autre compte
0- Retour
        ]
        @session_identifier = '10'
      end
    end
  end

  def get_paymoney_sold
    if @ussd_string.blank?
      @rendered_text = %Q[
      Veuillez entrer votre mot de passe PAYMONEY pour consulter votre solde.
      ]
      @session_identifier = '8'
    else
      account_profile = AccountProfile.find_by_msisdn(@msisdn[-8,8])
      @get_paymoney_sold_url = Parameter.first.paymoney_url + "/PAYMONEY_WALLET/rest/solte_compte/#{account_profile.paymoney_account_number}/#{@ussd_string}"
      @get_paymoney_sold_response = Typhoeus.get(@get_paymoney_sold_url, connecttimeout: 30)

      balance = JSON.parse(@get_paymoney_sold_response.body)["solde"] rescue nil
      if balance.blank?
        @rendered_text = %Q[
        Le mot de passe saisi n'est pas valide.
        Veuillez entrer votre mot de passe PAYMONEY pour consulter votre solde.
        ]
        @session_identifier = '8'
      else
        @rendered_text = %Q[
Votre solde PAYMONEY est de: #{balance rescue 0} FCFA

1- Jeux
2- Mes paris
3- Mon solde
4- Rechargement
5- Votre service SMS
6- Mes OTP
7- Mes comptes
        ]
        @session_identifier = '5'
      end
    end
  end

  def list_otp_set_session_identifier

  end

  def authenticate_or_create_parionsdirect_account(msisdn)
    @parionsdirect_password_url = Parameter.first.gateway_url + "/85fg69a7a9c59f3a0/api/users/password/#{msisdn[-8,8] rescue 0}"
    @parionsdirect_password_response = Typhoeus.get(@parionsdirect_password_url, connecttimeout: 30)
    password = @parionsdirect_password_response.body.split('-') rescue nil
    @password = password[0] rescue nil
    @salt = password[1] rescue nil

    if password.blank?
      # Le client n'a pas de compte parionsdirect et doit en créer un
      @rendered_text = %Q[Pour accéder à ce service, créez votre compte de jeu en entrant un mot de passe de 4 caractères.]
      @session_identifier = '1'
    else
      # Le client a un compte parionsdirect et doit s'authentifier
      @rendered_text = %Q[Veuillez entrer votre mot de passe parionsdirect.]
      @session_identifier = '2'
    end
  end

  def check_parionsdirect_password
    if @ussd_string.blank?
      # Le client n'a pas de compte parionsdirect et entrer un mot de passe pour en créer un
      @rendered_text = %Q[Veuillez entrer votre mot de passe parionsdirect.]
      @session_identifier = '2'
    else
      password = Digest::SHA2.hexdigest(@current_ussd_session.parionsdirect_salt + @ussd_string)
      if password == @current_ussd_session.parionsdirect_password
        existing_paymoney_account = AccountProfile.find_by_msisdn(@msisdn[-8,8])
        # On vérifie que le client n'a pas déjà de compte Paymoney associé à son numéro
        if existing_paymoney_account.blank?
          @rendered_text = %Q[
            Veuillez saisir votre numéro de compte Paymoney.
            ]
          @session_identifier = '4'
        else
          @rendered_text = %Q[
1- Jeux
2- Mes paris
3- Mon solde
4- Rechargement
5- Votre service SMS
6- Mes OTP
7- Mes comptes
          ]
          @session_identifier = '5'
        end
      else
        @rendered_text = %Q[Le mot de passe saisi n'est pas valide.
Veuillez entrer votre mot de passe parionsdirect.
          ]
        @session_identifier = '2'
      end
    end
  end

  def check_paymoney_account_number
    if @ussd_string.blank?
      # Le client saisit son numéro de compte Paymoney pour le faire valider
      @rendered_text = %Q[Veuillez saisir votre numéro de compte Paymoney.]
      @session_identifier = '4'
    else
      @check_pw_account_url = Parameter.first.paymoney_url + "/PAYMONEY_WALLET/rest/check2_compte/#{@ussd_string}"
      @check_pw_account_response = Typhoeus.get(@check_pw_account_url, connecttimeout: 30)

      if !@check_pw_account_response.body.blank? && @check_pw_account_response.body != 'null'
        @pw_account_number = @ussd_string
        @pw_account_token = @check_pw_account_response.body
        # On associe le compte Paymoney du client à son numéro
        AccountProfile.find_by_msisdn(@msisdn[-8,8]).update_attributes(paymoney_account_number: @pw_account_number) rescue AccountProfile.create(msisdn: @msisdn[-8,8], paymoney_account_number: @pw_account_number) rescue nil
        @rendered_text = %Q[
1- Jeux
2- Mes paris
3- Mon solde
4- Rechargement
5- Votre service SMS
6- Mes OTP
7- Mes comptes
          ]
        @session_identifier = '5'
      else
        @rendered_text = %Q[Le compte Paymoney fourni n'a pas été trouvé.
Veuillez saisir votre numéro de compte Paymoney.
          ]
        @session_identifier = '4'
      end
    end
  end

  # Création d'un nouveau compte parionsdirect par saisie du mot de passe
  def set_parionsdirect_password
    # L'utilisateur n'a pas saisi de mot de passe, on le ramène au menu précédent
    if @ussd_string.blank? || @ussd_string.length != 4
      # Le client n'a pas de compte parionsdirect et entrer un mot de passe pour en créer un
      @rendered_text = %Q[Pour accéder à ce service, créez votre compte de jeu en entrant un mot de passe de 4 caractères.]
      @session_identifier = '1'
    else
      @creation_pd_password = @ussd_string
      # Le client n'a pas de compte parionsdirect et confirmer le mot de passe pour en créer un
      @rendered_text = %Q[Veuillez confirmer le mot de passe précédemment entré.]
      @session_identifier = '3'
    end
  end

  # Création d'un nouveau compte parionsdirect par confirmation du mot de passe et création d'un compte paymoney
  def create_parionsdirect_account
    # L'utilisateur n'a pas saisi de confirmation de mot de passe, on le ramène au menu précédent
    if @ussd_string.blank? || @ussd_string.length != 4
      # Le client n'a pas de compte parionsdirect et confirmer le mot de passe pour en créer un
      @rendered_text = %Q[Veuillez confirmer le mot de passe précédemment entré.]
      @session_identifier = '3'
    else
      @creation_pd_password_confirmation = @ussd_string
      # Les mots de passe saisis ne sont pas identiques
      if @current_ussd_session.creation_pd_password != @creation_pd_password_confirmation
        # Le client n'a pas de compte parionsdirect et confirmer le mot de passe pour en créer un
        @rendered_text = %Q[Veuillez confirmer le mot de passe précédemment entré.]
        @session_identifier = '3'
      else
        @pseudo = "#{Digest::SHA1.hexdigest([DateTime.now.iso8601(6), rand].join).hex.to_s[0..8]}"
        @firstname = 'Parionsdirect'
        @lastname = 'Parionsdirect'
        @email = "ussd-#{Digest::SHA1.hexdigest([DateTime.now.iso8601(6), rand].join).hex.to_s[0..8]}@direct.ci"
        @birthdate = '12-12-1900'

        @creation_pd_request = Parameter.first.gateway_url + "/6ba041bf35229938ba869a7a9c59f3a0/api/users/account/create/1/1/#{@pseudo}/#{@firstname}/#{@lastname}/#{@email}/#{@current_ussd_session.creation_pd_password}/#{@creation_pd_password_confirmation}/#{@msisdn[-8,8]}/#{@birthdate}/d2a29d336c48fe68df6e5827cc49a042"
        @creation_pd_response = Typhoeus.get(@creation_pd_request, connecttimeout: 30)
        pd_account = JSON.parse(@creation_pd_response.body) rescue nil

        # Le compte parionsdirect n'a pas pu être créé
        if pd_account.blank? || !pd_account["errors"].blank?
          @pd_account_created = false
          @rendered_text = %Q[
            Une erreur s'est produite lors de la création du compte PARIONSDIRECT
            Veuillez confirmer le mot de passe précédemment entré.
            ]
          @session_identifier = '3'
        else
          @pd_account_created = true
          @rendered_text = %Q[
            Votre compte de jeu PARIONSDIRECT a été créé avec succès. Pour jouer, il vous faut un compte PAYMONEY. Avez vous un compte PAYMONEY?
            1- Oui
            2- Non
            ]
          @session_identifier = '4-'
        end
      end
    end
  end

  def create_paymoney_account
    if ['1', '2'].include?(@ussd_string)
      if @ussd_string == '2'
        # Création du compte paymoney du client
        @creation_pw_request = Parameter.first.paymoney_url + "/PAYMONEY_WALLET/rest/ussd_create_compte/#{@msisdn[-8,8]}"
        @creation_pw_response = Typhoeus.get(@creation_pw_request, connecttimeout: 30)
        paymoney_account = JSON.parse(@creation_pw_response.body) rescue nil
        # Le compte paymoney a été créé
        if (paymoney_account["errors"] rescue nil).blank?
          @pw_account_created = true
          @rendered_text = %Q[
            Vous allez recevoir un SMS avec  les détails de votre portemonnaie de jeux PAYMONEY.
            ]
          @session_identifier = '4'
        else
          @pw_account_created = false
          @rendered_text = %Q[
            Une erreur s'est produite lors de la création du compte Paymoney
            Veuillez confirmer le mot de passe précédemment entré.
            ]
          @session_identifier = '3'
        end
      else
        # Le client saisit son numéro de compte Paymoney pour le faire valider
        @rendered_text = %Q[Veuillez saisir votre numéro de compte Paymoney.]
        @session_identifier = '4'
      end
    else
      @rendered_text = %Q[
        Votre compte de jeu PARIONSDIRECT a été créé avec succès. Pour jouer, il vous faut un compte PAYMONEY. Avez vous un compte PAYMONEY?
        1- Oui
        2- Non
        ]
      @session_identifier = '4-'
    end
  end

  def set_main_menu_result_text(abort_reason, error_code)
    if abort_reason.blank?
      @result = %Q[
              <soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:loc="http://www.csapi.org/schema/parlayx/ussd/notification/v1_0/local">
                <soapenv:Header/>
                <soapenv:Body>
                  <loc:notifyUssdReceptionResponse>
                    <loc:result>#{error_code}</loc:result>
                  </loc:notifyUssdReceptionResponse>
                </soapenv:Body>
              </soapenv:Envelope>
            ]
    else
      @result = %Q[
              <soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:loc="http://www.csapi.org/schema/parlayx/ussd/notification/v1_0/local">
                <soapenv:Header/>
                <soapenv:Body>
                  <loc:notifyUssdAbortResponse/>
                </soapenv:Body>
              </soapenv:Envelope>
            ]
    end
  end

  def main_menu_parse_xml
    @rev_id = @received_body.xpath('//NotifySOAPHeader/spRevId').text rescue nil
    @rev_password = @received_body.xpath('//NotifySOAPHeader/spRevpassword').text rescue nil
    @sp_id = @received_body.xpath('//NotifySOAPHeader/spId').text rescue nil
    @linkid = @received_body.xpath('//NotifySOAPHeader/linkid').text rescue nil
    @service_id = @received_body.xpath('//NotifySOAPHeader/serviceId').text rescue nil
    @timestamp = @received_body.xpath('//NotifySOAPHeader/timeStamp').text rescue nil
    @unique_id = @received_body.xpath('//NotifySOAPHeader/traceUniqueID').text  rescue nil

    @msg_type = @received_body.xpath('//notifyUssdReception/msgType').text rescue nil
    @abort_reason = @received_body.xpath('//notifyUssdAbort/abortReason').text rescue nil
    @abort_reason.blank? ? (@sender_cb = @received_body.xpath('//notifyUssdReception/senderCB').text  rescue nil) : (@sender_cb = @received_body.xpath('//notifyUssdAbort/senderCB').text rescue nil)
    @abort_reason.blank? ? (@receive_cb = @received_body.xpath('//notifyUssdReception/receiveCB').text rescue nil) : (@receive_cb = @received_body.xpath('//notifyUssdAbort/receiveCB').text rescue nil)
    @ussd_op_type = @received_body.xpath('//notifyUssdReception/ussdOpType').text rescue nil
    @msisdn = @received_body.xpath('//notifyUssdReception/msIsdn').text rescue nil
    @service_code = @received_body.xpath('//notifyUssdReception/serviceCode').text rescue nil
    @code_scheme = @received_body.xpath('//notifyUssdReception/codeScheme').text rescue nil
    @ussd_string = @received_body.xpath('//notifyUssdReception/ussdString').text rescue nil
  end

  def c_main_menu_parse_xml
    if @raw_body.blank? || @received_body.blank?
      @error_code = 'NURR_1'
      @error_message = "Le document XML fourni n'est pas valide"
    end
  end

  def c_main_menu_check_sp_id
    if @sp_id != '2250110000460'
      @error_code = 'NURR_2'
      @error_message = "Le spId n'est pas valide"
    end
  end

  def c_main_menu_check_service_id
    if @service_id != '225012000003070'
      @error_code = 'NURR_3'
      @error_message = "Le serviceId n'est pas valide"
    end
  end

  def c_main_menu_check_unique_id
    if @unique_id.blank?
      @error_code = 'NURR_4'
      @error_message = "Le traceUniqueID est vide"
    end
  end

  def c_main_menu_check_msg_type
    if !['0', '1', '2'].include?(@msg_type)
      @error_code = 'NURR_5'
      @error_message = "Le msgType n'est pas valide"
    end
  end

  def c_main_menu_check_sender_cb
    if @sender_cb.blank?
      @error_code = 'NURR_6'
      @error_message = "Le senderCB est vide"
    end
  end

  def c_main_menu_check_receive_cb
    if @sender_cb.blank?
      @error_code = 'NURR_7'
      @error_message = "Le receiveCB est vide"
    end
  end

  def c_main_menu_check_ussd_op_type
    if !['1', '2', '3', '4'].include?(@ussd_op_type)
      @error_code = 'NURR_8'
      @error_message = "Le ussdOpType n'est pas valide"
    end
  end

  def c_main_menu_check_msisdn
    if @msisdn.blank?
      @error_code = 'NURR_9'
      @error_message = "Le msIsdn est vide"
    end
  end

  def c_main_menu_check_service_code
    if @service_code.blank?
      @error_code = 'NURR_10'
      @error_message = "Le serviceCode est vide"
    end
  end

  def c_main_menu_check_ussd_string
    if @ussd_string.blank?
      @error_code = 'NURR_11'
      @error_message = "L'ussdString est vide"
    end
  end

  def c_main_menu_check_linkid
    if @linkid.blank?
      @error_code = 'NURR_12'
      @error_message = "Le linkid est vide"
    end
  end

  def c_main_menu_abort_message?(abort_reason)
    if abort_reason.blank?
      @operation_type = "Send ussd"
    else
      @operation_type = "USSD abort"
      @error_code = 'NURR_13'
      @error_message = abort_reason
    end
  end

  def send_ussd(operation_type, msisdn, sender_cb, linkid, ussd_string)
    url = '196.201.33.108:8310/SendUssdService/services/SendUssd'
    sp_id = '2250110000460'
    service_id = '225012000003070'
    password = 'bmeB500'
    timestamp = DateTime.now.strftime('%Y%m%d%H%M%S')
    sp_password = Digest::MD5.hexdigest(sp_id + password + timestamp)
    present_id = ''
    msg_type = '1'
    sender_cb = sender_cb#Digest::SHA1.hexdigest([DateTime.now.iso8601(6), rand].join).hex.to_s[0..7]
    ussd_op_type = '1'
    service_code = '218'
    code_scheme = '15'
    ussd_stringue = %Q[
      1- Jeux
      2- Mes paris
      3- Mon solde
      4- Rechargement
      5- Votre service SMS
      6- Mes OTP - codes retraits
      7- Mes comptes
    ]
    endpoint = ''
    extenionInfo = ''

    request_body = %Q[
      <?xml version = "1.0" encoding = "utf-8" ?>
      <soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:loc="http://www.csapi.org/schema/parlayx/ussd/send/v1_0/local">
        <soapenv:Header>
          <tns:RequestSOAPHeader xmlns:tns="http://www.huawei.com.cn/schema/common/v2_1">
            <tns:spId>#{sp_id}</tns:spId>
            <tns:spPassword>#{sp_password}</tns:spPassword>
            <tns:serviceId>#{service_id}</tns:serviceId>
            <tns:timeStamp>#{timestamp}</tns:timeStamp>
            <tns:OA>#{msisdn}</tns:OA>
            <tns:FA>#{msisdn}</tns:FA>
            <tns:linkid>#{linkid}</tns:linkid>
          </tns:RequestSOAPHeader>
        </soapenv:Header>
        <soapenv:Body>
          <loc:sendUssd>
            <loc:msgType>#{msg_type}</loc:msgType>
            <loc:senderCB>#{sender_cb}</loc:senderCB>
            <loc:receiveCB>#{sender_cb}</loc:receiveCB>
            <loc:ussdOpType>1</loc:ussdOpType>
            <loc:msIsdn>#{msisdn}</loc:msIsdn>
            <loc:serviceCode>#{service_code}</loc:serviceCode>
            <loc:codeScheme>#{code_scheme}</loc:codeScheme>
            <loc:ussdString>#{ussd_string}</loc:ussdString>
          </loc:sendUssd>
        </soapenv:Body>
      </soapenv:Envelope>
    ]

    send_ussd_response = Typhoeus.post(url, body: request_body, connecttimeout: 30, headers: { 'Content-Type'=> "text/xml;charset=UTF-8" })

    nokogiri_response = (Nokogiri.XML(send_ussd_response.body) rescue nil)

    error_code = nokogiri_response.xpath('//soapenv:Fault').at('faultcode').content rescue nil
    error_message = nokogiri_response.xpath('//soapenv:Fault').at('faultstring').content rescue nil

    if error_code.blank?
      status = true
    else
      status = false
    end

    MtnStartSessionLog.create(operation_type: operation_type, request_url: url, request_log: request_body, response_log: send_ussd_response.body, request_code: send_ussd_response.code, total_time: send_ussd_response.total_time, request_headers: send_ussd_response.headers.to_s, error_code: error_code, error_message: error_message, status: status)
  end

  def start_ussd_log
    render text: MtnStartSessionLog.last.to_yaml
  end

  def base_numbers_overflow
    status = false
    @error_message
    # Champ reduit
    if @current_ussd_session.formula_label == 'Champ reduit' && (@ussd_string.split.length rescue 0) > ((@current_ussd_session.bet_selection == 'PN' ? 1 : @current_ussd_session.bet_selection.gsub('N', '').to_i) - 1)
      status = true
      @error_message = "Vous devez sélectionner au maximum #{((@current_ussd_session.bet_selection == 'PN' ? 1 : @current_ussd_session.bet_selection.gsub('N', '').to_i) - 1)} numéros"
    end
    # Champ total
    if @current_ussd_session.formula_label == 'Champ total' && (@ussd_string.split.length rescue 0) > ((@current_ussd_session.bet_selection == 'PN' ? 1 : @current_ussd_session.bet_selection.gsub('N', '').to_i) - 1)
      status = true
      @error_message = "Vous devez sélectionner au maximum #{((@current_ussd_session.bet_selection == 'PN' ? 1 : @current_ussd_session.bet_selection.gsub('N', '').to_i) - 1)}"
    end

    return status
  end

  def selection_numbers_overflow
    status = false
    @error_message
    # Simple
    if @current_ussd_session.formula_label == 'Simple' && (@ussd_string.split.length rescue 0) != (@current_ussd_session.bet_selection == 'PN' ? 1 : @current_ussd_session.bet_selection.gsub('N', '').to_i)
      status = true
      @error_message = "Vous devez sélectionner #{(@current_ussd_session.bet_selection == 'PN' ? 1 : @current_ussd_session.bet_selection.gsub('N', '').to_i)} numéros"
    end
    # Perm
    if @current_ussd_session.formula_label == 'Perm' && ((@ussd_string.split.length rescue 0) > 10 || (@ussd_string.split.length rescue 0) < (@current_ussd_session.bet_selection == 'PN' ? 1 : @current_ussd_session.bet_selection.gsub('N', '').to_i) + 1)
      status = true
      @error_message = "Vous devez sélectionner entre #{(@current_ussd_session.bet_selection == 'PN' ? 1 : @current_ussd_session.bet_selection.gsub('N', '').to_i) + 1} et 10 numéros"
    end

    return status
  end

  def invalid_base_numbers_range
    status = false
    @error_message = ''
    numbers = @ussd_string.split rescue []

    numbers.each do |number|
      if number.to_i < 1 || number.to_i > 90
        status = true
      end
    end

    if status
      @error_message = "Veuillez choisir des numéros compris entre 1 et 90  pour parier."
    end

    return status
  end

  def invalid_selection_numbers_range
    status = false
    @error_message = ''
    numbers = @ussd_string.split rescue []

    numbers.each do |number|
      if number.to_i < 1 || number.to_i > 90
        status = true
      end
    end

    if status
      @error_message = "Veuillez choisir des numéros compris entre 1 et 90  pour parier."
    end

    return status
  end

  def set_place_loto_bet_request_parameters
    @bet_code = ''
    case @current_ussd_session.bet_selection
      when 'PN'
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

    @selector1 = ''
    case @current_ussd_session.draw_day_shortcut
      when 'etoile'
        @selector1 = '1'
      when 'emergence'
        @selector1 = '5'
      when 'fortune'
        @selector1 = '2'
      when 'privilege'
        @selector1 = '6'
      when 'solution'
        @selector1 = '3'
      when 'diamant'
        @selector1 = '4'
      end

    @selector2 = ''
    case @current_ussd_session.draw_day_shortcut
      when 'etoile'
        @selector2 = -16 + DateTime.parse("01/01/#{Date.today.year} 19:00:00").upto(DateTime.now).count(&:monday?)
      when 'emergence'
        @selector2 = -16 + DateTime.parse("01/01/#{Date.today.year} 19:00:00").upto(DateTime.now).count(&:tuesday?)
      when 'fortune'
        @selector2 = -8 + DateTime.parse("01/01/#{Date.today.year} 19:00:00").upto(DateTime.now).count(&:wednesday?)
      when 'privilege'
        @selector2 = -16 + DateTime.parse("01/01/#{Date.today.year} 19:00:00").upto(DateTime.now).count(&:thursday?)
      when 'solution'
        @selector2 = -17 + DateTime.parse("01/01/#{Date.today.year} 19:00:00").upto(DateTime.now).count(&:friday?)
      when 'diamant'
        @selector2 = -8 + DateTime.parse("01/01/#{Date.today.year} 19:00:00").upto(DateTime.now).count(&:saturday?)
      end

    @begin_date = ''
    @end_date = ''
    case @current_ussd_session.draw_day_shortcut
      when 'etoile'
        @begin_date = Date.commercial(Date.today.year, Date.today.cwday.modulo(4)+Date.today.cweek, 1).strftime("%d-%m-%Y 19:00:00")
        @end_date = Date.commercial(Date.today.year, 1 + Date.today.cweek, 1).strftime("%d-%m-%Y 19:00:00")
      when 'emergence'
        @begin_date = Date.commercial(Date.today.year, Date.today.cwday.modulo(4)+Date.today.cweek, 2).strftime("%d-%m-%Y 19:00:00")
        @end_date = Date.commercial(Date.today.year, 1 + Date.today.cweek, 2).strftime("%d-%m-%Y 19:00:00")
      when 'fortune'
        @begin_date = Date.commercial(Date.today.year, Date.today.cwday.modulo(4)+Date.today.cweek, 3).strftime("%d-%m-%Y 19:00:00")
        @end_date = Date.commercial(Date.today.year, 1 + Date.today.cweek, 3).strftime("%d-%m-%Y 19:00:00")
      when 'privilege'
        @begin_date = Date.commercial(Date.today.year, Date.today.cwday.modulo(4)+Date.today.cweek, 4).strftime("%d-%m-%Y 19:00:00")
        @end_date = Date.commercial(Date.today.year, 1 + Date.today.cweek, 4).strftime("%d-%m-%Y 19:00:00")
      when 'solution'
        @begin_date = Date.commercial(Date.today.year, Date.today.cwday.modulo(4)+Date.today.cweek, 5).strftime("%d-%m-%Y 19:00:00")
        @end_date = Date.commercial(Date.today.year, 1 + Date.today.cweek, 5).strftime("%d-%m-%Y 19:00:00")
      when 'diamant'
        @begin_date = Date.commercial(Date.today.year, Date.today.cwday.modulo(4)+Date.today.cweek, 6).strftime("%d-%m-%Y 19:00:00")
        @end_date = Date.commercial(Date.today.year, 1 + Date.today.cweek, 6).strftime("%d-%m-%Y 19:00:00")
      end
  end

  def plr_get_reunions_list
    @get_plr_race_list_request = Parameter.first.parionsdirect_url + "/ussd_pmu/get_plr_race_list"
    @get_plr_race_list_response = RestClient.get(@get_plr_race_list_request) rescue nil
    @reunions = []

    races = JSON.parse(@get_plr_race_list_response) rescue nil
    races = races["plr_race_list"] rescue nil

    unless races.blank?
      races.each do |race|
        if !@reunions.include?(race["reunion"])
          @reunions << race["reunion"]
        end
      end
    end
  end

  def plr_get_reunion
    @rendered_text = %Q[PMU PLR

Veuillez entrer le numéro de réunion]
    @session_identifier = '20'
  end

  def plr_get_race
    if @ussd_string.blank?
      @rendered_text = %Q[PMU PLR
Veuillez entrer le numéro de réunion]
      @session_identifier = '20'
    else
      plr_get_reunions_list
      @get_plr_race_list_request = @get_plr_race_list_request
      @get_plr_race_list_response = @get_plr_race_list_response

      if !@reunions.include?('R' + @ussd_string)
        @rendered_text = %Q[PMU PLR
Veuillez entrer un numéro de réunion valide]
        @session_identifier = '20'
      else
        @rendered_text = %Q[PMU PLR
Réunion: R#{@ussd_string}
Veuillez entrer le numéro de course]
        @session_identifier = '21'
      end
    end
  end

  def plr_game_selection
    if @ussd_string.blank?
      @rendered_text = %Q[PMU PLR
Réunion: R#{@ussd_string}
Veuillez entrer le numéro de course valide]
      @session_identifier = '21'
    else
      status = false
      JSON.parse(@current_ussd_session.get_plr_race_list_response)["plr_race_list"].each do |race|
        if 'R' + @current_ussd_session.plr_reunion_number == race["reunion"] && ('C' + @ussd_string) == race["course"]
          status = true
        end
      end

      if status == false
        @rendered_text = %Q[PMU PLR
Réunion: R#{@ussd_string}
Veuillez entrer le numéro de course valide]
      @session_identifier = '21'
      else
        @rendered_text = %Q[PMU PLR
Vous avez sélectionné la course: Réunion: R#{@current_ussd_session.plr_reunion_number} - Course: C#{@ussd_string}

1- Jouer
2- Détail des courses]
        @session_identifier = '22'
      end
    end
  end

  def set_session_identifier_depending_on_plr_game_selection
    @status = false
    if !['1', '2'].include?(@ussd_string)
      @rendered_text = %Q[PMU PLR
Vous avez sélectionné la course: Réunion: R#{@current_ussd_session.plr_reunion_number} - Course: C#{@ussd_string}

1- Jouer
2- Détail des courses]
      @session_identifier = '22'
    else
      @status = true
    end
  end

  def display_plr_race_details
    @plr_race_details_request = Parameter.first.parionsdirect_url + "/ussd_pmu/get_plr_race_list_info/R#{@current_ussd_session.plr_reunion_number}/C#{@current_ussd_session.plr_race_number}"
    races = RestClient.get(@plr_race_details_request) rescue nil
    @plr_race_details_response = races

    races = JSON.parse(races) rescue nil
    races = races["plr_race_list"] rescue nil
    @rendered_text = ""

    races.each do |race|
      @rendered_text << %Q[PMU PLR
Numéro de course: #{race["numero_course"]} - Départ: #{race["depart"]}
Réunion: #{race["reunion"]} - Course: #{race["course"]}
Nombre de partants: #{race["Partants"]}
Détails: #{race["details"]}]
    end
  end

  def display_plr_bet_type
    @rendered_text = %Q[Réunion: R#{@current_ussd_session.plr_reunion_number} - Course: C#{@current_ussd_session.plr_race_number}
1- Trio
2- Jumelé gagnant
3- Jumelé placé
4- Simple gagnant
5- Simple placé]
    @session_identifier = '23'
  end

  def set_session_identifier_depending_on_plr_bet_type_selected
    @status = false
    if ['1', '2', '3', '4', '5'].include?(@ussd_string)
      @status = true
    else
      @rendered_text = %Q[Réunion: R#{@current_ussd_session.plr_reunion_number} - Course: C#{@current_ussd_session.plr_race_number}
1- Trio
2- Jumelé gagnant
3- Jumelé placé
4- Simple gagnant
5- Simple placé]
      @session_identifier = '23'
    end
  end

  def set_session_identifier_depending_on_plr_formula_selected
    @status = false
    if ['1', '2', '3'].include?(@ussd_string)
      @status = true
    else
      @rendered_text = %Q[Réunion: R#{@current_ussd_session.plr_reunion_number} - Course: C#{@current_ussd_session.plr_race_number}
1- Long champ
2- Champ réduit
3- Champ total]
      @session_identifier = '23'
    end
  end

  def plr_display_plr_formula
    @rendered_text = %Q[Réunion: R#{@current_ussd_session.plr_reunion_number} - Course: C#{@current_ussd_session.plr_race_number}
1- Long champ
2- Champ réduit
3- Champ total]
    @session_identifier = '24'
  end

  def plr_display_plr_selection
    @rendered_text = %Q[Réunion: R#{@current_ussd_session.plr_reunion_number} - Course: C#{@current_ussd_session.plr_race_number}
Saisissez les numéros de vos chevaux en les séparant par un espace]
    @session_identifier = '26'
  end

  def plr_display_plr_base
    @rendered_text = %Q[Réunion: R#{@current_ussd_session.plr_reunion_number} - Course: C#{@current_ussd_session.plr_race_number}
Saisissez la base]
    @session_identifier = '25'
  end

  def plr_select_number_of_times
    @ussd_string = @ussd_string
    if plr_valid_horses_numbers
      if plr_right_selection
        if plr_numbers_in_selection_not_in_base
          @rendered_text = %Q[Réunion: R#{@current_ussd_session.plr_reunion_number} - Course: C#{@current_ussd_session.plr_race_number}
Veuillez saisir le nombre de fois que vous souhaitez miser]
          @session_identifier = '27'
        else
          @rendered_text = %Q[#{@error_message}
Réunion: R#{@current_ussd_session.plr_reunion_number} - Course: C#{@current_ussd_session.plr_race_number}
Saisissez les numéros de vos chevaux en les séparant par un espace]
          @session_identifier = '26'
        end
      else
        @rendered_text = %Q[#{@error_message}
Réunion: R#{@current_ussd_session.plr_reunion_number} - Course: C#{@current_ussd_session.plr_race_number}
Saisissez les numéros de vos chevaux en les séparant par un espace]
        @session_identifier = '26'
      end
    else
      @rendered_text = %Q[#{@error_message}
Réunion: R#{@current_ussd_session.plr_reunion_number} - Course: C#{@current_ussd_session.plr_race_number}
Saisissez les numéros de vos chevaux en les séparant par un espace]
      @session_identifier = '26'
    end
  end

  def plr_valid_horses_numbers
    status = true

    if @ussd_string.blank?
      status = false
    else
      @ussd_string.split.each do |horse_number|
        if not_a_number?(horse_number)
          status = false
        end
      end
    end

    return status
  end

  def plr_right_selection
    status = true
    @error_message = ""
    if @current_ussd_session.plr_bet_type_shortcut == "simple_gagnant" && @ussd_string.split.length > 10
      @error_message = "Vous pouvez sélectionner 10 numéros au maximum"
      status = false
    end
    if @current_ussd_session.plr_bet_type_shortcut == "simple_place" && @ussd_string.split.length > 10
      @error_message = "Vous pouvez sélectionner 10 numéros au maximum"
      status = false
    end
    if @current_ussd_session.plr_bet_type_shortcut == "jumele_gagnant" && (@ussd_string.split.length > 10 || @ussd_string.split.length < 2)
      @error_message = "Vous pouvez sélectionner entre 2 et 10 numéros"
      status = false
    end
    if @current_ussd_session.plr_bet_type_shortcut == "jumele_gagnant" && @current_ussd_session.plr_formula_shortcut == "long_champs" && (@ussd_string.split.length > 10 || @ussd_string.split.length < 2)
      @error_message = "Vous pouvez sélectionner entre 2 et 10 numéros"
      status = false
    end
    if @current_ussd_session.plr_bet_type_shortcut == "jumele_place" && (@ussd_string.split.length > 10 || @ussd_string.split.length < 2)
      @error_message = "Vous pouvez sélectionner entre 2 et 10 numéros"
      status = false
    end
    if @current_ussd_session.plr_bet_type_shortcut == "jumele_place" && @current_ussd_session.plr_formula_shortcut == "long_champs" && (@ussd_string.split.length > 10 || @ussd_string.split.length < 2)
      @error_message = "Vous pouvez sélectionner entre 2 et 10 numéros"
      status = false
    end
    if @current_ussd_session.plr_bet_type_shortcut == "trio" && (@ussd_string.split.length > 10 || @ussd_string.split.length < 3)
      @error_message = "Vous pouvez sélectionner entre 3 et 10 numéros"
      status = false
    end
    if @current_ussd_session.plr_bet_type_shortcut == "trio" && @current_ussd_session.plr_formula_shortcut == "long_champs" && (@ussd_string.split.length > 10 || @ussd_string.split.length < 3)
      @error_message = "Vous pouvez sélectionner entre 3 et 10 numéros"
      status = false
    end
    if @current_ussd_session.plr_bet_type_shortcut == "champ_reduit"  && @ussd_string.split.length < 5
      @error_message = "Vous devez sélectionner au moins 5 numéros"
      status = false
    end

    return status
  end

  def plr_numbers_in_selection_not_in_base
    status = true
    @error_message = ""
    if !@current_ussd_session.plr_base.blank?
      @current_ussd_session.plr_base.split(",").each do |base_number|
        if @ussd_string.split.include?(base_number)
          @error_message = 'Veuillez choisir des numéros en sélection différents de ceux en base'
          status = false
        end
      end
    end

    return status
  end

  # Controler les numéros de base
  def plr_selection_or_stake_depending_on_formula
    if @current_ussd_session.plr_formula_shortcut == 'champ_reduit'
      @rendered_text = %Q[Réunion: R#{@current_ussd_session.plr_reunion_number} - Course: C#{@current_ussd_session.plr_race_number}
Saisissez les numéros de vos chevaux en les séparant par un espace]
      @session_identifier = '26'
    else
      @rendered_text = %Q[Réunion: R#{@current_ussd_session.plr_reunion_number} - Course: C#{@current_ussd_session.plr_race_number}
Veuillez saisir le nombre de fois que vous souhaitez miser]
      @session_identifier = '27'
    end
  end

  def plr_evaluate_bet
    @error_message = ''
    if @ussd_string.blank? || not_a_number?(@ussd_string)
      @rendered_text = %Q[Réunion: R#{@current_ussd_session.plr_reunion_number} - Course: C#{@current_ussd_session.plr_race_number}
Veuillez saisir le nombre de fois que vous souhaitez miser]
      @session_identifier = '27'
    else
      plr_set_bet_code_and_modifier
      @current_ussd_session = @current_ussd_session
      @plr_evaluate_bet_request = Parameter.first.gateway_url + "/ail/pmu/api/3c9342cf06/bet/query"
      @request_body = %Q[
                    {
                      "bet_code":"#{@bet_code}",
                      "bet_modifier":"#{@bet_modifier}",
                      "selector1":"#{@current_ussd_session.plr_reunion_number}",
                      "selector2":"#{@current_ussd_session.plr_race_number}",
                      "repeats":"#{@ussd_string}",
                      "special_entries":"#{@current_ussd_session.plr_base.blank? ? '' : @current_ussd_session.plr_base.split.join(',')}",
                      "normal_entries":"#{@current_ussd_session.plr_selection.blank? ? '' : @current_ussd_session.plr_selection.split.join(',')}"
                    }
                  ]
      @plr_evaluate_bet_response = Typhoeus::Request.new(
        @plr_evaluate_bet_request,
        method: :post,
        body: @request_body
      )
      @plr_evaluate_bet_response.run
      @plr_evaluate_bet_response = @plr_evaluate_bet_response.response.body rescue nil
      json_object = JSON.parse(@plr_evaluate_bet_response) rescue nil

      if json_object.blank?
        @rendered_text = %Q[Le pari n'a pas pu être évalué
Réunion: R#{@current_ussd_session.plr_reunion_number} - Course: C#{@current_ussd_session.plr_race_number}
Veuillez saisir le nombre de fois que vous souhaitez miser]
        @session_identifier = '27'
      else
        if json_object["error"].blank?
          @rendered_text = %Q[Vous vous apprêtez à prendre un pari PMU PLR
R#{@current_ussd_session.plr_reunion_number}C#{@current_ussd_session.plr_race_number}
#{@current_ussd_session.plr_bet_type_label} > #{@current_ussd_session.plr_formula_label}
#{@current_ussd_session.plr_base.blank? ? '' : "Base: " + @current_ussd_session.plr_base}
#{@current_ussd_session.plr_selection.blank? ? '' : "Sélection: " + @current_ussd_session.plr_selection}
Votre pari est estimé à #{json_object["bet"]["bet_cost_amount"]} FCFA.
Confirmez en saisissant votre code secret]
          @bet_cost_amount = json_object["bet"]["bet_cost_amount"]
          @session_identifier = '28'
        else
          @rendered_text = %Q[Le pari n'a pas pu être évalué
Réunion: R#{@current_ussd_session.plr_reunion_number} - Course: C#{@current_ussd_session.plr_race_number}
Veuillez saisir le nombre de fois que vous souhaitez miser]
          @session_identifier = '27'
        end
      end
    end
  end

  def plr_place_bet
    if @ussd_string.blank?
      @rendered_text = %Q[Vous vous apprêtez à prendre un pari PMU PLR
R#{@current_ussd_session.plr_reunion_number}C#{@current_ussd_session.plr_race_number}
#{@current_ussd_session.plr_bet_type_label} > #{@current_ussd_session.plr_formula_label}
#{@current_ussd_session.plr_base.blank? ? '' : "Base: " + @current_ussd_session.plr_base}
#{@current_ussd_session.plr_selection.blank? ? '' : "Sélection: " + @current_ussd_session.plr_selection}
Votre pari est estimé à #{@current_ussd_session.bet_cost_amount} FCFA.
Confirmez en saisissant votre code secret]
      @session_identifier = '28'
    else
      @get_gamer_id_request = Parameter.first.gateway_url + "/8ba869a7a9c59f3a0/api/users/gamer_id/#{@account_profile.msisdn}"
      @get_gamer_id_response = Typhoeus.get(@get_gamer_id_request, connecttimeout: 30)
      if @get_gamer_id_response.body.blank?
        @rendered_text = %Q[Votre identifiant parieur n'a pas pu être récupéré.
R#{@current_ussd_session.plr_reunion_number}C#{@current_ussd_session.plr_race_number}
#{@current_ussd_session.plr_bet_type_label} > #{@current_ussd_session.plr_formula_label}
#{@current_ussd_session.plr_base.blank? ? '' : "Base: " + @current_ussd_session.plr_base}
#{@current_ussd_session.plr_selection.blank? ? '' : "Sélection: " + @current_ussd_session.plr_selection}
Votre pari est estimé à #{@current_ussd_session.bet_cost_amount} FCFA.
Confirmez en saisissant votre code secret]
        @session_identifier = '28'
      else
        @plr_place_bet_request = Parameter.first.gateway_url + "/ail/pmu/api/dik749742e/bet/place/#{@get_gamer_id_response.body}/#{@account_profile.paymoney_account_number}/#{@ussd_string}"
        plr_set_bet_code_and_modifier

        @body = %Q[
                    {
                      "bet_code":"#{@bet_code}",
                      "bet_modifier":"#{@bet_modifier}",
                      "selector1":"#{@current_ussd_session.plr_reunion_number}",
                      "selector2":"#{@current_ussd_session.plr_race_number}",
                      "repeats":"#{@current_ussd_session.plr_number_of_times}",
                      "special_entries":"#{@current_ussd_session.plr_base.blank? ? '' : @current_ussd_session.plr_base.split.join(',') rescue ''}",
                      "normal_entries":"#{@current_ussd_session.plr_selection.blank? ? '' : @current_ussd_session.plr_selection.split.join(',') rescue ''}",
                      "race_details":"#{JSON.parse(@current_ussd_session.plr_race_details_response)["plr_race_list"].first["details"] rescue ''}",
                      "begin_date":"#{ Date.today.strftime('%d-%m-%Y') + ' ' + (JSON.parse(@current_ussd_session.plr_race_details_response)["plr_race_list"].first["depart"].gsub('H', ':') rescue '') + ':00'}",
                      "end_date":""
                    }
                  ]
        request = Typhoeus::Request.new(
        @plr_place_bet_request,
        method: :post,
        body: @body
        )
        request.run
        @plr_place_bet_response = request.response
        json_object = JSON.parse(@plr_place_bet_response.body) rescue nil
        if json_object.blank?
          @rendered_text = %Q[Le pari n'a pas pu être placé.
R#{@current_ussd_session.plr_reunion_number}C#{@current_ussd_session.plr_race_number}
#{@current_ussd_session.plr_bet_type_label} > #{@current_ussd_session.plr_formula_label}
#{@current_ussd_session.plr_base.blank? ? '' : "Base: " + @current_ussd_session.plr_base}
#{@current_ussd_session.plr_selection.blank? ? '' : "Sélection: " + @current_ussd_session.plr_selection}
Votre pari est estimé à #{@current_ussd_session.bet_cost_amount} FCFA.
Confirmez en saisissant votre code secret]
          @session_identifier = '28'
        else
          if json_object["error"].blank?
            status = true
            @rendered_text = %Q[PMU PLR – R#{@current_ussd_session.plr_reunion_number}C#{@current_ussd_session.plr_race_number}
#{@current_ussd_session.plr_bet_type_label} > #{@current_ussd_session.plr_formula_label}
#{@current_ussd_session.plr_base.blank? ? '' : "Base: " + @current_ussd_session.plr_base}
#{@current_ussd_session.plr_selection.blank? ? '' : "Sélection: " + @current_ussd_session.plr_selection}
N° de ticket: #{json_object["bet"]["ticket_number"]}]
            @session_identifier = '29'
          else
            @rendered_text = %Q[Le pari n'a pas pu être placé.
R#{@current_ussd_session.plr_reunion_number}C#{@current_ussd_session.plr_race_number}
#{@current_ussd_session.plr_bet_type_label} > #{@current_ussd_session.plr_formula_label}
#{@current_ussd_session.plr_base.blank? ? '' : "Base: " + @current_ussd_session.plr_base}
#{@current_ussd_session.plr_selection.blank? ? '' : "Sélection: " + @current_ussd_session.plr_selection}
Votre pari est estimé à #{@current_ussd_session.bet_cost_amount} FCFA.
Confirmez en saisissant votre code secret]
            @session_identifier = '28'
          end
        end
      end
    end
  end

  def plr_set_bet_code_and_modifier
    @bet_code = ''
    @bet_modifier = ''

    if @current_ussd_session.plr_bet_type_shortcut == 'simple_gagnant'
      @bet_code = '100'
      @bet_modifier = '0'
    end
    if @current_ussd_session.plr_bet_type_shortcut == 'simple_place'
      @bet_code = '101'
      @bet_modifier = '0'
    end
    if @current_ussd_session.plr_bet_type_shortcut == 'jumele_gagnant'
      case @current_ussd_session.plr_formula_shortcut
        when 'long_champs'
          @bet_code = '107'
          @bet_modifier = '0'
        when 'champ_reduit'
          @bet_code = '111'
          @bet_modifier = '0'
        when 'champ_total'
          @bet_code = '109'
          @bet_modifier = '0'
        end
    end
    if @current_ussd_session.plr_bet_type_shortcut == 'jumele_place'
      case @current_ussd_session.plr_formula_shortcut
        when 'long_champs'
          @bet_code = '108'
          @bet_modifier = '0'
        when 'champ_reduit'
          @bet_code = '112'
          @bet_modifier = '0'
        when 'champ_total'
          @bet_code = '110'
          @bet_modifier = '0'
        end
    end
    if @current_ussd_session.plr_bet_type_shortcut == 'trio'
      if @current_ussd_session.plr_formula_shortcut == 'long_champs'
        @bet_code = '102'
        @bet_modifier = '0'
      end
      if @current_ussd_session.plr_formula_shortcut == 'champ_reduit'
        if @current_ussd_session.plr_base.split(',').length == 1
          @bet_code = '104'
          @bet_modifier = '0'
        else
          @bet_code = '106'
          @bet_modifier = '0'
        end
      end
      if @current_ussd_session.plr_formula_shortcut == 'champ_total'
        if @current_ussd_session.plr_base.split(',').length == 1
          @bet_code = '103'
          @bet_modifier = '0'
        else
          @bet_code = '105'
          @bet_modifier = '0'
        end
      end
    end
  end

  def alr_display_races
    @alr_get_current_program_request = Parameter.first.parionsdirect_url + "/ussd_pmu/get_alr_current_program"
    @alr_get_current_program_response = Typhoeus.get(@alr_get_current_program_request, connecttimeout: 30)

    current_program = JSON.parse(@alr_get_current_program_response.body) rescue nil
    @alr_program_id = current_program["program_id"] rescue nil
    @alr_program_date = current_program["program_date"] rescue nil
    @alr_program_status = current_program["status"] rescue nil
    @alr_race_ids = current_program["race_ids"] rescue nil#.split('-') rescue []

    @alr_race_list_request = Parameter.first.parionsdirect_url + "/ussd_pmu/get_alr_race_list"
    @alr_race_list_response = Typhoeus.get(@alr_race_list_request, connecttimeout: 30)

    @race_data = @alr_race_list_response.body rescue nil#JSON.parse(@alr_race_list_response.body)["alr_race_list"] rescue nil

    if @alr_program_status != 'ON' || @alr_race_ids.length == 0 || @race_data.blank?
      @rendered_text = %Q[PMU - ALR - Il n'y a aucun programme disponible
1- Loto Bonheur
2- PMU ALR
3- PMU PLR
4- SPORTCASH]
      @session_identifier = '11'
    else
      races = ""
      @alr_race_ids.split('-').each do |race_id|
         races << race_id[-1,1] + " - Nationale" + race_id[-1,1] + "
"
      end
      @rendered_text = %Q[PMU - ALR
#{races}]
      @session_identifier = '30'
    end
  end

  def alr_display_bet_type
    status = false
    @current_ussd_session.alr_race_ids.split('-').each do |race_id|
       if @ussd_string == race_id[-1,1]
         status = true
       end
    end

    if status
      @national_label = "Nationale #{@ussd_string}"
      @national_shortcut = @ussd_string
      @race_details = ""
      @bet_types = ""
      @alr_bet_type_menu = ""
      race_datum = JSON.parse(@current_ussd_session.race_data)["alr_race_list"]
      if race_datum.blank?
        @race_details =
        @bet_types = "Paris fermés pour cette course"
      else
        custom_index = 0
        race_datum.each do |race_data|
          if race_data["race_id"] == @current_ussd_session.alr_program_id + '0' + @national_shortcut
            bet_ids = race_data["bet_ids"].gsub('-SALE', '').split(',') rescue []
            @race_details << race_data["name"] + "
"
            @race_details << "Nombre de partants: " + race_data["max_runners"] + "
"
            @race_details << "Non partants: " + race_data["scratched_list"] + "
Veuillez choisir votre type de pari
"
            if bet_ids.include?('4')
              @race_details << "#{custom_index+=1}- Couplé placé
"
              @alr_bet_type_menu << "#{custom_index}-couple_place "
            end
            if bet_ids.include?('2')
              @race_details << "#{custom_index+=1}- Couplé gagnant
"
              @alr_bet_type_menu << "#{custom_index}-couple_gagnant "
            end
            if bet_ids.include?('7')
              @race_details << "#{custom_index+=1}- Tiercé
"
              @alr_bet_type_menu << "#{custom_index}-tierce "
            end
            if bet_ids.include?('14')
              @race_details << "#{custom_index+=1}- Tiercé
"
              @alr_bet_type_menu << "#{custom_index}-tierce "
            end
            if bet_ids.include?('8')
              @race_details << "#{custom_index+=1}- Quarté
"
              @alr_bet_type_menu << "#{custom_index}-quarte "
            end
            if bet_ids.include?('10')
              @race_details << "#{custom_index+=1}- Quinté
"
              @alr_bet_type_menu << "#{custom_index}-quinte "
            end
            if bet_ids.include?('11')
              @race_details << "#{custom_index+=1}- Quinté +
"
              @alr_bet_type_menu << "#{custom_index}-quinte_plus "
            end
            if bet_ids.include?('13')
              @race_details << "#{custom_index+=1}- Multi"
              @alr_bet_type_menu << "#{custom_index}-multi "
            end
          end
        end
      end

      @rendered_text = %Q[PMU - ALR
#{@national_label}
#{@race_details}]
      @session_identifier = '31'
    else
      races = ""
      @current_ussd_session.alr_race_ids.split('-').each do |race_id|
         races << race_id[-1,1] + " - Nationale" + race_id[-1,1] + "
"
      end
      @rendered_text = %Q[PMU - ALR
#{races}]
      @session_identifier = '30'
    end
  end

  def alr_display_formula
    custom_index = 0
    @race_header = ""
    @race_details = ""
    @alr_bet_type_menu = ""
    race_datum = JSON.parse(@current_ussd_session.race_data)["alr_race_list"]
    race_datum.each do |race_data|
      if race_data["race_id"] == @current_ussd_session.alr_program_id + '0' + @current_ussd_session.national_shortcut
        bet_ids = race_data["bet_ids"].gsub('-SALE', '').split(',') rescue []
        @race_header << race_data["name"] + "
"
        @race_header << "Nombre de partants: " + race_data["max_runners"] + "
"
        @race_header << "Non partants: " + race_data["scratched_list"] + "
Veuillez choisir votre type de pari
"
        if bet_ids.include?('4')
          @race_details << "#{custom_index+=1}- Couplé placé
"
          @alr_bet_type_menu << "#{custom_index}-couple_place "
        end
        if bet_ids.include?('2')
          @race_details << "#{custom_index+=1}- Couplé gagnant
"
          @alr_bet_type_menu << "#{custom_index}-couple_gagnant "
        end
        if bet_ids.include?('7')
          @race_details << "#{custom_index+=1}- Tiercé
"
          @alr_bet_type_menu << "#{custom_index}-tierce "
        end
        if bet_ids.include?('14')
          @race_details << "#{custom_index+=1}- Tiercé
"
          @alr_bet_type_menu << "#{custom_index}-tierce "
        end
        if bet_ids.include?('8')
          @race_details << "#{custom_index+=1}- Quarté
"
          @alr_bet_type_menu << "#{custom_index}-quarte "
        end
        if bet_ids.include?('10')
          @race_details << "#{custom_index+=1}- Quinté
"
          @alr_bet_type_menu << "#{custom_index}-quinte "
        end
        if bet_ids.include?('11')
          @race_details << "#{custom_index+=1}- Quinté +
"
          @alr_bet_type_menu << "#{custom_index}-quinte_plus "
        end
        if bet_ids.include?('13')
          @race_details << "#{custom_index+=1}- Multi"
          @alr_bet_type_menu << "#{custom_index}-multi "
        end
      end
    end

    if @ussd_string.to_i.between?(1, @current_ussd_session.alr_bet_type_menu.split().length)
      @bet_type = @current_ussd_session.alr_bet_type_menu.split()[@ussd_string.to_i - 1].split('-')[1] rescue nil

      case @bet_type
        when 'multi'
          @bet_type_label = 'Multi'
          @alr_bet_id = '13'
        when 'couple_place'
          @bet_type_label = 'Couplé placé'
          @alr_bet_id = '4'
        when 'couple_gagnant'
          @bet_type_label = 'Couplé gagnant'
          @alr_bet_id = '2'
        when 'tierce'
          @bet_type_label = 'Tiercé'
          @alr_bet_id = '7'
        when 'quarte'
          @bet_type_label = 'Quarté'
          @alr_bet_id = '8'
        when 'quinte'
          @bet_type_label = 'Quinté'
          @alr_bet_id = '10'
        when 'quinte_plus'
          @bet_type_label = 'Quinté +'
          @alr_bet_id = '11'
      end

      if @bet_type == 'multi'
        @rendered_text = %Q[PMU - ALR
#{@current_ussd_session.national_label} > #{@bet_type_label}
#{@race_header}
1- Multi 4/4
2- Multi 4/5
3- Multi 4/6
4- Multi 4/7]
        @session_identifier = '33'
      else
        @rendered_text = %Q[PMU - ALR
#{@current_ussd_session.national_label} > #{@bet_type_label}
#{@race_header}
1- Long champ
2- Champ réduit
3- Champ total]
        @session_identifier = '32'
      end
    else

      @rendered_text = %Q[PMU - ALR
#{@current_ussd_session.national_label}
#{@race_header}
#{@race_details}]
      @session_identifier = '31'
    end
  end

  def set_session_identifier_depending_on_alr_bet_type_selected
    @status = false
    if ['1', '2', '3'].include?(@ussd_string)
      @status = true
    else
      @race_header = ""
      race_datum = JSON.parse(@current_ussd_session.race_data)["alr_race_list"]
      race_datum.each do |race_data|
        if race_data["race_id"] == @current_ussd_session.alr_program_id + '0' + @current_ussd_session.national_shortcut
          bet_ids = race_data["bet_ids"].gsub('-SALE', '').split(',') rescue []
          @race_header << race_data["name"] + "
"
          @race_header << "Nombre de partants: " + race_data["max_runners"] + "
"
          @race_header << "Non partants: " + race_data["scratched_list"] + "
  Veuillez choisir votre type de pari
"
        end
      end
      @rendered_text = %Q[PMU - ALR
#{@current_ussd_session.national_label} > #{@current_ussd_session.alr_bet_type_label}
#{@race_header}
1- Long champ
2- Champ réduit
3- Champ total]
      @session_identifier = '32'
    end
  end

  def set_session_identifier_depending_on_alr_multi_selected
    @status = false
    if ['1', '2', '3', '4'].include?(@ussd_string)
      @status = true
    else
      @race_header = ""
      race_datum = JSON.parse(@current_ussd_session.race_data)["alr_race_list"]
      race_datum.each do |race_data|
        if race_data["race_id"] == @current_ussd_session.alr_program_id + '0' + @current_ussd_session.national_shortcut
          bet_ids = race_data["bet_ids"].gsub('-SALE', '').split(',') rescue []
          @race_header << race_data["name"] + "
"
          @race_header << "Nombre de partants: " + race_data["max_runners"] + "
"
          @race_header << "Non partants: " + race_data["scratched_list"] + "
  Veuillez choisir votre type de pari
"
        end
      end
      @rendered_text = %Q[PMU - ALR
#{@current_ussd_session.national_label} > #{@bet_type_label}
#{@race_header}
1- Multi 4/4
2- Multi 4/5
3- Multi 4/6
4- Multi 4/7]
      @session_identifier = '33'
    end
  end

  def alr_select_horses
    @race_header = ""
    race_datum = JSON.parse(@current_ussd_session.race_data)["alr_race_list"]
    race_datum.each do |race_data|
      if race_data["race_id"] == @current_ussd_session.alr_program_id + '0' + @current_ussd_session.national_shortcut
        bet_ids = race_data["bet_ids"].gsub('-SALE', '').split(',') rescue []
        @race_header << race_data["name"] + "
"
        @race_header << "Nombre de partants: " + race_data["max_runners"] + "
"
        @race_header << "Non partants: " + race_data["scratched_list"] + "
"
      end
    end

    @current_ussd_session.alr_base.blank? ? base = '' : base = %Q[
#{@current_ussd_session.alr_base}]
    @rendered_text = %Q[PMU - ALR
#{@current_ussd_session.national_label} > #{@current_ussd_session.alr_bet_type_label}#{base}
#{@race_header}
Saisissez les numéros de vos chevaux séparés par un espace]
    @session_identifier = '35'
  end

  def alr_select_base
    @race_header = ""
    race_datum = JSON.parse(@current_ussd_session.race_data)["alr_race_list"]
    race_datum.each do |race_data|
      if race_data["race_id"] == @current_ussd_session.alr_program_id + '0' + @current_ussd_session.national_shortcut
        bet_ids = race_data["bet_ids"].gsub('-SALE', '').split(',') rescue []
        @race_header << race_data["name"] + "
"
        @race_header << "Nombre de partants: " + race_data["max_runners"] + "
"
        @race_header << "Non partants: " + race_data["scratched_list"] + "
"
      end
    end

    @rendered_text = %Q[PMU - ALR
#{@current_ussd_session.national_label} > #{@current_ussd_session.alr_bet_type_label}
#{@race_header}
Saisissez le numero de votre cheval de BASE et ulitiser X pour definir l'emplacement de votre selection]
    @session_identifier = '34'
  end

  def alr_set_full_formula
    @race_header = ""
    race_datum = JSON.parse(@current_ussd_session.race_data)["alr_race_list"]
    race_datum.each do |race_data|
      if race_data["race_id"] == @current_ussd_session.alr_program_id + '0' + @current_ussd_session.national_shortcut
        bet_ids = race_data["bet_ids"].gsub('-SALE', '').split(',') rescue []
        @race_header << race_data["name"] + "
"
        @race_header << "Nombre de partants: " + race_data["max_runners"] + "
"
        @race_header << "Non partants: " + race_data["scratched_list"] + "
"
      end
    end

    if ['1', '2'].include?(@ussd_string)
      @ussd_string == '1' ? @full_formula = true : @full_formula = false
      @rendered_text = %Q[PMU - ALR
#{@current_ussd_session.national_label} > #{@current_ussd_session.alr_bet_type_label}
#{@race_header}
Saisissez le nombre de fois]
      @session_identifier = '37'
    else
      @rendered_text = %Q[PMU - ALR
#{@current_ussd_session.national_label} > #{@current_ussd_session.alr_bet_type_label}
#{@race_header}
Voulez-vous jouer en formule complète?
1- Oui
2- Non]
    end
  end

  def validate_alr_base
    @ussd_string = @ussd_string
    @current_ussd_session = @current_ussd_session
    @race_header = ""
    race_datum = JSON.parse(@current_ussd_session.race_data)["alr_race_list"]
    race_datum.each do |race_data|
      if race_data["race_id"] == @current_ussd_session.alr_program_id + '0' + @current_ussd_session.national_shortcut
        bet_ids = race_data["bet_ids"].gsub('-SALE', '').split(',') rescue []
        @race_header << race_data["name"] + "
"
        @race_header << "Nombre de partants: " + race_data["max_runners"] + "
"
        @race_header << "Non partants: " + race_data["scratched_list"] + "
"
      end
    end

    if alr_valid_base_numbers
      session[:alr_base] = @ussd_string.split.join(',')
      if @current_ussd_session.alr_formula_label == 'Champ réduit'
        @current_ussd_session.alr_base.blank? ? base = '' : base = %Q[
#{@current_ussd_session.alr_base}]
        @rendered_text = %Q[PMU - ALR
#{@current_ussd_session.national_label} > #{@current_ussd_session.alr_bet_type_label}#{base}
#{@race_header}
Saisissez les numéros de vos chevaux séparés par un espace]
        @session_identifier = '35'
      else
        if @current_ussd_session.alr_formula_label == 'Champ total'
          @rendered_text = %Q[PMU - ALR
#{@current_ussd_session.national_label} > #{@current_ussd_session.alr_bet_type_label}
#{@race_header}
Voulez-vous jouer en formule complète?
1- Oui
2- Non]
          @session_identifier = '36'
        else
          @rendered_text = %Q[PMU - ALR
#{@current_ussd_session.national_label} > #{@current_ussd_session.alr_bet_type_label}
#{@race_header}
Saisissez le nombre de fois]
          @session_identifier = '37'
        end
      end
    else
      @rendered_text = %Q[PMU - ALR
#{@current_ussd_session.national_label} > #{@current_ussd_session.alr_bet_type_label}
#{@race_header}
Saisissez le numero de votre cheval de BASE et ulitiser X pour definir l'emplacement de votre selection]
    @session_identifier = '34'
    end
  end

  def validate_alr_horses
    @ussd_string = @ussd_string
    @current_ussd_session = @current_ussd_session
    @race_header = ""
    race_datum = JSON.parse(@current_ussd_session.race_data)["alr_race_list"]
    race_datum.each do |race_data|
      if race_data["race_id"] == @current_ussd_session.alr_program_id + '0' + @current_ussd_session.national_shortcut
        bet_ids = race_data["bet_ids"].gsub('-SALE', '').split(',') rescue []
        @race_header << race_data["name"] + "
"
        @race_header << "Nombre de partants: " + race_data["max_runners"] + "
"
        @race_header << "Non partants: " + race_data["scratched_list"] + "
"
      end
    end

    if alr_valid_horses_numbers
      if alr_valid_multi_number_of_horses && alr_valid_selection_numbers
        if ['Tiercé', 'Quarté', 'Quinté', 'Quinté +'].include?(@current_ussd_session.alr_bet_type_label)
          @rendered_text = %Q[PMU - ALR
#{@current_ussd_session.national_label} > #{@current_ussd_session.alr_bet_type_label}
#{@race_header}
Voulez-vous jouer en formule complète?
1- Oui
2- Non]
          @session_identifier = '36'
        else
          @rendered_text = %Q[PMU - ALR
#{@current_ussd_session.national_label} > #{@current_ussd_session.alr_bet_type_label}
#{@race_header}
Saisissez le nombre de fois]
          @session_identifier = '37'
        end
      else
        @rendered_text = %Q[#{@error_message}
PMU - ALR
#{@current_ussd_session.national_label} > #{@current_ussd_session.alr_bet_type_label}
#{@race_header}
Saisissez les numéros de vos chevaux séparés par un espace]
        @session_identifier = '35'
      end
    else
      @rendered_text = %Q[#{@error_message}
PMU - ALR
#{@current_ussd_session.national_label} > #{@current_ussd_session.alr_bet_type_label}
#{@race_header}
Saisissez les numéros de vos chevaux séparés par un espace]
      @session_identifier = '35'
    end
  end

  def alr_evaluate_bet
    @current_ussd_session = @current_ussd_session
    @ussd_string = @ussd_string
    @race_header = ""
    race_datum = JSON.parse(@current_ussd_session.race_data)["alr_race_list"]
    race_datum.each do |race_data|
      if race_data["race_id"] == @current_ussd_session.alr_program_id + '0' + @current_ussd_session.national_shortcut
        bet_ids = race_data["bet_ids"].gsub('-SALE', '').split(',') rescue []
        @race_header << race_data["name"] + "
"
        @race_header << "Nombre de partants: " + race_data["max_runners"] + "
"
        @race_header << "Non partants: " + race_data["scratched_list"] + "
"
      end
    end
    if @ussd_string.blank? || not_a_number?(@ussd_string)
      @rendered_text = %Q[PMU - ALR
#{@current_ussd_session.national_label} > #{@current_ussd_session.alr_bet_type_label}
#{@race_header}
Saisissez le nombre de fois]
      @session_identifier = '37'
    else
      @program_id = @current_ussd_session.alr_program_id
      @race_id = @current_ussd_session.alr_race_ids.split('-')[@current_ussd_session.national_shortcut.to_i - 1] rescue nil

      @alr_evaluate_bet_request = Parameter.first.gateway_url + "/cm3/api/0cad36b144/game/evaluate/#{@current_ussd_session.alr_program_id}/#{@race_id}"
      comma = @current_ussd_session.alr_selection.blank? ? '' : ','
      items = @current_ussd_session.alr_base + (@current_ussd_session.alr_base.blank? ? '' : comma) + @current_ussd_session.alr_selection
      @body = %Q(
                    {
                      "games":[
                        {
                          "game_id":"1",
                          "bet_id":"#{@current_ussd_session.alr_bet_id}",
                          "nb_units":"#{@ussd_string}",
                          "full_box":"#{@current_ussd_session.full_formula == true ? 'TRUE' : 'FALSE'}",
                          "items":[#{items.gsub(/x/i, %Q/"X"/)}]
                        }
                      ]
                    }
                  )
      request = Typhoeus::Request.new(
        @alr_evaluate_bet_request,
        method: :post,
        body: @body
      )
      request.run
      @alr_evaluate_bet_response = request.response

      json_object = JSON.parse(@alr_evaluate_bet_response.body) rescue nil
      if json_object.blank?
        @rendered_text = %Q[PMU - ALR
Le pari n'a pas pu être évalué
#{@current_ussd_session.national_label} > #{@current_ussd_session.alr_bet_type_label}
#{@race_header}
Saisissez le nombre de fois]
        @session_identifier = '37'
      else
        if json_object["error"].blank?
          @alr_scratched_list = json_object["evaluations"]["scratched"]
          @alr_combinations = json_object["evaluations"]["evaluations"].first["nb_combinations"]
          @alr_amount = json_object["evaluations"]["evaluations"].first["amount"]
          @rendered_text = %Q[
Vous vous apprêtez à prendre un pari PMU ALR
#{@current_ussd_session.national_label} > #{@current_ussd_session.alr_bet_type_label}
#{@race_header}
#{@current_ussd_session.alr_base.blank? ? '' : "Base: " + @current_ussd_session.alr_base}
#{@current_ussd_session.alr_selection.blank? ? '' : "Sélection: " + @current_ussd_session.alr_selection}
Votre pari est estimé à #{@alr_amount} FCFA
Veuillez entrer votre mot de passe Paymoney pour valider le pari.]
          @session_identifier = '38'
        else
          @rendered_text = %Q[PMU - ALR
Le pari n'a pas pu être évalué
#{@current_ussd_session.national_label} > #{@current_ussd_session.alr_bet_type_label}
#{@race_header}
Saisissez le nombre de fois]
          @session_identifier = '37'
        end
      end
    end
  end

  def alr_place_bet
    if @ussd_string.length != 4 || not_a_number?(@ussd_string)
      @race_header = ""
      race_datum = JSON.parse(@current_ussd_session.race_data)["alr_race_list"]
      race_datum.each do |race_data|
        if race_data["race_id"] == @current_ussd_session.alr_program_id + '0' + @current_ussd_session.national_shortcut
          bet_ids = race_data["bet_ids"].gsub('-SALE', '').split(',') rescue []
          @race_header << race_data["name"] + "
  "
          @race_header << "Nombre de partants: " + race_data["max_runners"] + "
  "
          @race_header << "Non partants: " + race_data["scratched_list"] + "
  "
        end
      end

      @rendered_text = %Q[Vous vous apprêtez à prendre un pari PMU ALR
#{@current_ussd_session.national_label} > #{@current_ussd_session.alr_bet_type_label}
#{@race_header}
#{@current_ussd_session.alr_base.blank? ? '' : "Base: " + @current_ussd_session.alr_base}
#{@current_ussd_session.alr_selection.blank? ? '' : "Sélection: " + @current_ussd_session.alr_selection}
Votre pari est estimé à #{@current_ussd_session.alr_amount} FCFA
Veuillez entrer votre mot de passe Paymoney pour valider le pari.]
      @session_identifier = '38'
    else
      @get_gamer_id_request = Parameter.first.gateway_url + "/8ba869a7a9c59f3a0/api/users/gamer_id/#{@account_profile.msisdn}"
      @get_gamer_id_response = Typhoeus.get(@get_gamer_id_request, connecttimeout: 30)
      if @get_gamer_id_response.body.blank?
        @rendered_text = %Q[Votre identifiant parieur n'a pas pu être récupéré
Vous vous apprêtez à prendre un pari PMU ALR
#{@current_ussd_session.national_label} > #{@current_ussd_session.alr_bet_type_label}
#{@race_header}
#{@current_ussd_session.alr_base.blank? ? '' : "Base: " + @current_ussd_session.alr_base}
#{@current_ussd_session.alr_selection.blank? ? '' : "Sélection: " + @current_ussd_session.alr_selection}
Votre pari est estimé à #{@current_ussd_session.alr_amount} FCFA
Veuillez entrer votre mot de passe Paymoney pour valider le pari.]
        @session_identifier = '38'
      else
        @program_id = @current_ussd_session.alr_program_id
        @race_id = @current_ussd_session.alr_race_ids.split('-')[@current_ussd_session.national_shortcut.to_i - 1] rescue nil
        @alr_place_bet_request = Parameter.first.gateway_url + "/cm3/api/98d24611fd/ticket/sell/#{@get_gamer_id_response.body}/#{@account_profile.paymoney_account_number}/#{@ussd_string}/#{@current_ussd_session.alr_program_date}/#{@current_ussd_session.alr_program_date}"
        comma = @current_ussd_session.alr_selection.blank? ? '' : ','
        items = @current_ussd_session.alr_base + (@current_ussd_session.alr_base.blank? ? '' : comma) + @current_ussd_session.alr_selection
        @body = %Q(
                      {
                        "program_id":"#{@current_ussd_session.alr_program_id}",
                        "race_id":"#{@race_id}",
                        "amount":"#{@current_ussd_session.alr_amount}",
                        "scratched_list":#{@current_ussd_session.alr_scratched_list},
                        "wagers":[
                          {
                            "bet_id":"#{@current_ussd_session.alr_bet_id}",
                            "nb_units":"#{@current_ussd_session.alr_stake}",
                            "nb_combinations":"#{@current_ussd_session.alr_combinations}",
                            "full_box":"#{@current_ussd_session.full_formula == true ? 'TRUE' : 'FALSE'}",
                            "selection":[#{items.gsub(/x/i, %Q/"X"/)}]
                          }
                        ]
                      }
                    )
        request = Typhoeus::Request.new(
          @alr_place_bet_request,
          method: :post,
          body: @body
        )
        request.run
        @alr_place_bet_response = request.response

        json_object = JSON.parse(@alr_place_bet_response.body) rescue nil
        if json_object.blank?
          @rendered_text = %Q[Votre identifiant parieur n'a pas pu être récupéré
Vous vous apprêtez à prendre un pari PMU ALR
#{@current_ussd_session.national_label} > #{@current_ussd_session.alr_bet_type_label}
#{@race_header}
#{@current_ussd_session.alr_base.blank? ? '' : "Base: " + @current_ussd_session.alr_base}
#{@current_ussd_session.alr_selection.blank? ? '' : "Sélection: " + @current_ussd_session.alr_selection}
Votre pari est estimé à #{@current_ussd_session.alr_amount} FCFA
Veuillez entrer votre mot de passe Paymoney pour valider le pari.]
          @session_identifier = '38'
        else
          if json_object["error"].blank?
            @rendered_text = %Q[Votre ticket a été validé
#{@current_ussd_session.national_label} > #{@current_ussd_session.alr_bet_type_label}
#{@race_header}
#{@current_ussd_session.alr_base.blank? ? '' : "Base: " + @current_ussd_session.alr_base}
#{@current_ussd_session.alr_selection.blank? ? '' : "Sélection: " + @current_ussd_session.alr_selection}
Numéro de ticket: #{json_object["bet"]["serial_number"]}
            ]
            @session_identifier = '39'
          else
            @rendered_text = %Q[Votre identifiant parieur n'a pas pu être récupéré
Vous vous apprêtez à prendre un pari PMU ALR
#{@current_ussd_session.national_label} > #{@current_ussd_session.alr_bet_type_label}
#{@race_header}
#{@current_ussd_session.alr_base.blank? ? '' : "Base: " + @current_ussd_session.alr_base}
#{@current_ussd_session.alr_selection.blank? ? '' : "Sélection: " + @current_ussd_session.alr_selection}
Votre pari est estimé à #{@current_ussd_session.alr_amount} FCFA
Veuillez entrer votre mot de passe Paymoney pour valider le pari.]
            @session_identifier = '38'
          end
        end
      end
    end
  end

  def alr_valid_horses_numbers
    status = true

    if @ussd_string.blank?
      status = false
    else
      @ussd_string.split.each do |horse_number|
        if not_a_number?(horse_number) && horse_number.upcase != 'X'
          status = false
        end
      end
    end

    return status
  end

  def alr_valid_multi_number_of_horses
    status = true
    @error_message = ""
    if @current_ussd_session.alr_bet_type_label == 'Multi' && @current_ussd_session.alr_formula_label == ' 4/4'
      @error_message = "Vous devez sélectionner 4 chevaux"
      status = false
    end
    if @current_ussd_session.alr_bet_type_label == 'Multi' && @current_ussd_session.alr_formula_label == ' 4/5'
      @error_message = "Vous devez sélectionner 5 chevaux"
      status = false
    end
    if @current_ussd_session.alr_bet_type_label == 'Multi' && @current_ussd_session.alr_formula_label == ' 4/6'
      @error_message = "Vous devez sélectionner 6 chevaux"
      status = false
    end
    if @current_ussd_session.alr_bet_type_label == 'Multi' && @current_ussd_session.alr_formula_label == ' 4/7'
      @error_message = "Vous devez sélectionner 7 chevaux"
      status = false
    end

    return status
  end

  def alr_valid_selection_numbers
    status = true
    if @current_ussd_session.alr_bet_type_label == 'Couplé gagnant' && @current_ussd_session.alr_formula_label == 'Champ réduit' && @ussd_string.split.length < 1
      @error_message = "Vous devez choisir au moins 1 numéro"
      status = false
    end
    if @current_ussd_session.alr_bet_type_label == 'Couplé gagnant'  && @ussd_string.split.length < 2
      @error_message = "Vous devez choisir au moins 2 numéros"
      status = false
    end
    if @current_ussd_session.alr_bet_type_label == 'Tiercé' && @current_ussd_session.alr_formula_label == 'Champ réduit' && @ussd_string.split.length < 2
      @error_message = "Vous devez choisir au moins 2 numéros"
      status = false
    end
    if @current_ussd_session.alr_bet_type_label == 'Tiercé' && @ussd_string.split.length < 3
      @error_message = "Vous devez choisir au moins 3 numéros"
      status = false
    end
    if @current_ussd_session.alr_bet_type_label == 'Quarté' && @current_ussd_session.alr_formula_label == 'Champ réduit' && @ussd_string.split.length < 3
      @error_message = "Vous devez choisir au moins 3 numéros"
      status = false
    end
    if @current_ussd_session.alr_bet_type_label == 'Quarté' && @ussd_string.split.length < 4
      @error_message = "Vous devez choisir au moins 4 numéros"
      status = false
    end
    if (@current_ussd_session.alr_bet_type_label == 'Quinté' || @current_ussd_session.alr_bet_type_label == 'Quinté +') && @current_ussd_session.alr_formula_label == 'Champ réduit' && @ussd_string.split.length < 4
      @error_message = "Vous devez choisir au moins 4 numéros"
      status = false
    end
    if (@current_ussd_session.alr_bet_type_label == 'Quinté' || @current_ussd_session.alr_bet_type_label == 'Quinté +') && @ussd_string.split.length < 5
      @error_message = "Vous devez choisir au moins 5 numéros"
      status = false
    end
    return status
  end

  def alr_valid_base_numbers
    status = true
    @error_message = ""

    if @ussd_string.blank?
      status = false
      @error_message = "Veuillez entrer des numéros de chevaux valides"
    else
      @ussd_string.split.each do |horse_number|
        if not_a_number?(horse_number) && horse_number.upcase != 'X'
          status = false
          @error_message = "Veuillez entrer des numéros de chevaux valides"
        end
      end
    end

    if @current_ussd_session.alr_bet_type_label == 'Couplé gagnant' && @current_ussd_session.alr_formula_label == 'Champ réduit' && @ussd_string.split.length != 2 && !@ussd_string.split.include?('X') && !@ussd_string.split.include?('x')
      @error_message = "Vous devez choisir 1 numéro"
      status = false
    end
    if @current_ussd_session.alr_bet_type_label == 'Couplé gagnant' && @current_ussd_session.alr_formula_label == 'Champ total' && @ussd_string.split.length != 2 && !@ussd_string.split.include?('X') && !@ussd_string.split.include?('x')
      @error_message = "Vous devez choisir 1 numéro"
      status = false
    end
    if @current_ussd_session.alr_bet_type_label == 'Couplé placé' && @current_ussd_session.alr_formula_label == 'Champ réduit' && @ussd_string.split.length != 2 && !@ussd_string.split.include?('X') && !@ussd_string.split.include?('x')
      @error_message = "Vous devez choisir 1 numéro"
      status = false
    end
    if @current_ussd_session.alr_bet_type_label == 'Tiercé' && @current_ussd_session.alr_formula_label == 'Champ réduit' && @ussd_string.split.length > 3 && !@ussd_string.split.include?('X')
      @error_message = "Vous devez choisir au plus 2 numéros"
      status = false
    end
    if @current_ussd_session.alr_bet_type_label == 'Tiercé' && @current_ussd_session.alr_formula_label == 'Champ total' && @ussd_string.split.length > 3 && !@ussd_string.split.include?('X')
      @error_message = "Vous devez choisir au plus 2 numéros"
      status = false
    end
    if @current_ussd_session.alr_bet_type_label == 'Quarté' && @current_ussd_session.alr_formula_label == 'Champ réduit' && @ussd_string.split.length > 4 && !@ussd_string.split.include?('X')
      @error_message = "Vous devez choisir au plus 3 numéros"
      status = false
    end
    if @current_ussd_session.alr_bet_type_label == 'Quarté' && @current_ussd_session.alr_formula_label == 'Champ total' && @ussd_string.split.length > 4 && !@ussd_string.split.include?('X')
      @error_message = "Vous devez choisir au plus 3 numéros"
      status = false
    end
    if (@current_ussd_session.alr_bet_type_label == 'Quinté' || @current_ussd_session.alr_bet_type_label == 'Quinté +') && @current_ussd_session.alr_formula_label == 'Champ réduit' && @ussd_string.split.length > 5 && !@ussd_string.split.include?('X')
      @error_message = "Vous devez choisir au plus 4 numéros"
      status = false
    end
    if (@current_ussd_session.alr_bet_type_label == 'Quinté' || @current_ussd_session.alr_bet_type_label == 'Quinté +') && @ussd_string.split.length > 5 && !@ussd_string.split.include?('X')
      @error_message = "Vous devez choisir au plus 4 numéros"
      status = false
    end

    return status
  end

end
