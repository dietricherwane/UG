class UssdTestingController < ApplicationController

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

  def exit_menu(sender_cb, msg)
    url = '196.201.33.108:8310/SendUssdService/services/SendUssd'
    sp_id = '2250110000460'
    service_id = '225012000003070'
    password = 'bmeB500'
    timestamp = DateTime.now.strftime('%Y%m%d%H%M%S')
    sp_password = Digest::MD5.hexdigest(sp_id + password + timestamp)
    service_code = '218'
    code_scheme = '15'
    @exit = true

    request_body = %Q[
      <?xml version = "1.0" encoding = "utf-8" ?>
      <soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:loc="http://www.csapi.org/schema/parlayx/ussd/send/v1_0/local">
        <soapenv:Header>
          <tns:RequestSOAPHeader xmlns:tns="http://www.huawei.com.cn/schema/common/v2_1">
            <tns:spId>#{sp_id}</tns:spId>
            <tns:spPassword>#{sp_password}</tns:spPassword>
            <tns:serviceId>#{service_id}</tns:serviceId>
            <tns:timeStamp>#{timestamp}</tns:timeStamp>
            <tns:OA>#{@msisdn}</tns:OA>
            <tns:FA>#{@msisdn}</tns:FA>
            <tns:linkid>#{@linkid}</tns:linkid>
          </tns:RequestSOAPHeader>
        </soapenv:Header>
        <soapenv:Body>
          <loc:sendUssd>
            <loc:msgType>2</loc:msgType>
            <loc:senderCB>#{sender_cb}</loc:senderCB>
            <loc:receiveCB>#{sender_cb}</loc:receiveCB>
            <loc:ussdOpType>3</loc:ussdOpType>
            <loc:msIsdn>#{@msisdn}</loc:msIsdn>
            <loc:serviceCode>#{service_code}</loc:serviceCode>
            <loc:codeScheme>#{code_scheme}</loc:codeScheme>
            <loc:ussdString>#{msg}</loc:ussdString>
          </loc:sendUssd>
        </soapenv:Body>
      </soapenv:Envelope>
    ]

=begin
    request_body = %Q[
      <soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:loc="http://www.csapi.org/schema/osg/ussd/notification_manager/v1_0/local">
        <soapenv:Header>
          <tns:RequestSOAPHeader xmlns:tns="http://www.huawei.com.cn/schema/common/v2_1">
            <tns:spId>#{sp_id}</tns:spId>
            <tns:spPassword>#{sp_password}</tns:spPassword>
            <tns:serviceId>#{service_id}</tns:serviceId>
            <tns:timeStamp>#{timestamp}</tns:timeStamp>
            <tns:OA>8613300000010</tns:OA>
            <tns:FA>8613300000010</tns:FA>
          </tns:RequestSOAPHeader>
        </soapenv:Header>
        <soapenv:Body>
          <loc:sendUssdAbort>
            <loc:senderCB>#{sender_cb}</loc:senderCB>
            <loc:receiveCB>#{sender_cb}</loc:receiveCB>
            <loc:abortReason>sp abort</loc:abortReason>
          </loc:sendUssdAbort>
        </soapenv:Body>
      </soapenv:Envelope>
    ]
=end
    exit_session_response = Typhoeus.post(url, body: request_body, connecttimeout: 30)

    nokogiri_response = (Nokogiri.XML(exit_session_response.body) rescue nil)

    error_code = nokogiri_response.xpath('//soapenv:Fault').at('faultcode').content rescue nil
    error_message = nokogiri_response.xpath('//soapenv:Fault').at('faultstring').content rescue nil

    MtnStartSessionLog.create(operation_type: "Exit session", request_url: url, request_log: request_body, response_log: exit_session_response.body, request_code: exit_session_response.code, total_time: exit_session_response.total_time, request_headers: exit_session_response.headers.to_s, error_code: error_code, error_message: error_message)

    #render text: '0'
  end

  def back_to_home
    @rendered_text = %Q[BIENVENUE DANS LE MENU LONACI:
1- Recharger compte de jeu
2- Jouer
3- Termes et conditions]
    @session_identifier = '5--'
    @current_ussd_session.update_attributes(session_identifier: @session_identifier)
  end

  def back_list_main_menu
    @rendered_text = %Q[BIENVENUE DANS LE MENU LONACI:
1- Recharger compte de jeu
2- Jouer
3- Termes et conditions]
    @session_identifier = '5--'
    @current_ussd_session.update_attributes(session_identifier: @session_identifier)
  end

  def back_display_loto_draw_day
    reference_date = "01/01/#{Date.today.year} 19:00:00"
    @rendered_text = %Q[
1- Etoile #{(35 + DateTime.parse(reference_date).upto(DateTime.now).count(&:monday?)).to_s}
2- Emergence #{(36 + DateTime.parse(reference_date).upto(DateTime.now).count(&:tuesday?)).to_s}
3- Fortune #{(44 + DateTime.parse(reference_date).upto(DateTime.now).count(&:wednesday?)).to_s}
4- Privilège #{(36 + DateTime.parse(reference_date).upto(DateTime.now).count(&:thursday?)).to_s}
5- Solution #{(36 + DateTime.parse(reference_date).upto(DateTime.now).count(&:friday?)).to_s}
6- Diamant #{(45 + DateTime.parse(reference_date).upto(DateTime.now).count(&:saturday?)).to_s}
0- Retour
00- Accueil]
    @session_identifier = '12'
    @current_ussd_session.update_attributes(session_identifier: @session_identifier)
  end

  def back_display_bet_selection
    @rendered_text = %Q[#{@current_ussd_session.draw_day_label}
1- PN - 1 numéro
2- 2N - 2 numéro
3- 3N - 3 numéro
4- 4N - 4 numéro
5- 5N - 5 numéro
0- Retour
00- Accueil]
    @session_identifier = '13'
    @current_ussd_session.update_attributes(session_identifier: @session_identifier)
  end

  def back_display_formula_selection
    @rendered_text = %Q[Loto bonheur - #{@bet_selection}
Choisissez votre formule

1- Simple
2- Perm]
    if @bet_selection != 'PN'
      @rendered_text << %Q[
3- Champ réduit
4- Champ total]
    end
    @rendered_text << %Q[
0- Retour
00- Accueil]
    @session_identifier = '14'
    @current_ussd_session.update_attributes(session_identifier: @session_identifier)
  end

  def back_display_base_selection
    @rendered_text = %Q[Loto bonheur - #{@current_ussd_session.draw_day_label} #{@current_ussd_session.bet_selection} #{@formula_label}
#{@current_ussd_session.bet_selection == 'PN' ? 'Saisissez votre numéro' : "Saisissez vos numéros séparés d'un espace"} (Entre 1 et 90)
Veuillez entrer votre base.
0- Retour
00- Accueil]
    @session_identifier = '15'
    @current_ussd_session.update_attributes(session_identifier: @session_identifier)
  end

  def back_display_selection
    @rendered_text = %Q[Loto bonheur - #{@current_ussd_session.draw_day_label} #{@current_ussd_session.bet_selection} #{@current_ussd_session.formula_label}
 #{!@current_ussd_session.base_field.blank? ? "Base: " + @current_ussd_session.base_field : ""}
 #{@current_ussd_session.bet_selection == 'PN' ? 'Saisissez votre numéro' : "Saisissez vos numéros séparés d'un espace"} (Entre 1 et 90)
Veuillez entrer votre sélection.
0- Retour
00- Accueil]
    @session_identifier = '16'
    @current_ussd_session.update_attributes(session_identifier: @session_identifier)
  end

  def back_evaluate_bet
    @rendered_text = %Q[Veuillez entrer une mise de base valide
Loto bonheur - #{@current_ussd_session.draw_day_label} #{@current_ussd_session.bet_selection} #{@current_ussd_session.formula_label}
#{!@current_ussd_session.base_field.blank? ? "Base: " + @current_ussd_session.base_field : ""}
#{!@current_ussd_session.selection_field.blank? ? "Sélection: " + @current_ussd_session.selection_field : ""}
Veuillez entrer votre mise de base.
0- Retour
00- Accueil]
    @session_identifier = '17'
  end

  def back_to_plr_get_reunion
    @rendered_text = %Q[PMU PLR
Veuillez entrer le numéro de réunion
#{@reunion_string}
0- Retour
00- Accueil]
    @session_identifier = '20'
    @current_ussd_session.update_attributes(session_identifier: @session_identifier)
  end

  def back_to_plr_get_race
    @reunions = []
    @reunion_string = ""
    @race_string = ""
    races = JSON.parse(@current_ussd_session.get_plr_race_list_response) rescue nil
    races = races["plr_race_list"] rescue nil

    unless races.blank?
      races.each do |race|
        if race["reunion"] == "R" + @current_ussd_session.plr_reunion_number
          @race_string << "#{race["course"]}" << " #{race["depart"]}" << "
"
        end
      end
    end
    @rendered_text = %Q[PMU PLR
Réunion: R#{@current_ussd_session.plr_reunion_number}
#{@race_string}
0- Retour
00- Accueil]
    @session_identifier = '21'
    @current_ussd_session.update_attributes(session_identifier: @session_identifier)
  end

  def back_to_plr_gaming_menu
    @rendered_text = %Q[PMU PLR
Vous avez sélectionné la course: Réunion: R#{@current_ussd_session.plr_reunion_number} - Course: C#{@current_ussd_session.plr_race_number}
1- Jouer
2- Détail des courses
0- Retour
00- Accueil]
    @session_identifier = '22'
    @current_ussd_session.update_attributes(session_identifier: @session_identifier)
  end

  def back_to_plr_bet_type
    @rendered_text = %Q[Réunion: R#{@current_ussd_session.plr_reunion_number} - Course: C#{@current_ussd_session.plr_race_number}
1- Trio
2- Jumelé gagnant
3- Jumelé placé
4- Simple gagnant
5- Simple placé
0- Retour
00- Accueil]
    @session_identifier = '23'
    @current_ussd_session.update_attributes(session_identifier: @session_identifier)
  end

  def back_to_plr_select_formula
    @rendered_text = %Q[Réunion: R#{@current_ussd_session.plr_reunion_number} - Course: C#{@current_ussd_session.plr_race_number}
1- Long champ
2- Champ réduit
3- Champ total
0- Retour
00- Accueil]
    @session_identifier = '24'
    @current_ussd_session.update_attributes(session_identifier: @session_identifier)
  end

  def back_to_plr_select_base
    @rendered_text = %Q[Réunion: R#{@current_ussd_session.plr_reunion_number} - Course: C#{@current_ussd_session.plr_race_number}
Saisissez la base
0- Retour
00- Accueil]
    @session_identifier = '25'
    @current_ussd_session.update_attributes(session_identifier: @session_identifier)
  end

  def back_to_plr_select_selection
    @rendered_text = %Q[Réunion: R#{@current_ussd_session.plr_reunion_number} - Course: C#{@current_ussd_session.plr_race_number}
Saisissez les numéros de vos chevaux en les séparant par un espace
0- Retour
00- Accueil]
    @session_identifier = '26'
    @current_ussd_session.update_attributes(session_identifier: @session_identifier)
  end

  def back_to_plr_select_stake
    @rendered_text = %Q[Le pari n'a pas pu être évalué
    Réunion: R#{@current_ussd_session.plr_reunion_number} - Course: C#{@current_ussd_session.plr_race_number}
    Veuillez saisir le nombre de fois que vous souhaitez miser]
    @session_identifier = '27'
    @current_ussd_session.update_attributes(session_identifier: @session_identifier)
  end

  def back_alr_list_races
    races = ""
    @current_ussd_session.alr_race_ids.split('-').each do |race_id|
       races << race_id[-1,1] + " - Nationale" + race_id[-1,1] + "
"
    end
    @rendered_text = %Q[PMU - ALR
#{races}
0- Retour
00- Accueil]
    @session_identifier = '30'
    @current_ussd_session.update_attributes(session_identifier: @session_identifier)
  end

  def back_to_alr_display_formula
    custom_index = 0
    @race_header = ""
    @race_details = ""
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
        end
        if bet_ids.include?('2')
          @race_details << "#{custom_index+=1}- Couplé gagnant
"
        end
        if bet_ids.include?('7')
          @race_details << "#{custom_index+=1}- Tiercé
"
        end
        if bet_ids.include?('14')
          @race_details << "#{custom_index+=1}- Tiercé 2
"
        end
        if bet_ids.include?('8')
          @race_details << "#{custom_index+=1}- Quarté
"
        end
        if bet_ids.include?('10')
          @race_details << "#{custom_index+=1}- Quinté
"
        end
        if bet_ids.include?('11')
          @race_details << "#{custom_index+=1}- Quinté +
"
        end
        if bet_ids.include?('13')
          @race_details << "#{custom_index+=1}- Multi"
        end
      end
    end
    @rendered_text = %Q[PMU - ALR
#{@current_ussd_session.national_label}
#{@race_header}
#{@race_details}
0- Retour
00- Accueil]
    @session_identifier = '31'
    @current_ussd_session.update_attributes(session_identifier: @session_identifier)
  end

  def alr_generic_race_header(current_ussd_session)
    @race_header = ""
    race_datum = JSON.parse(current_ussd_session.race_data)["alr_race_list"]
    race_datum.each do |race_data|
      if race_data["race_id"] == current_ussd_session.alr_program_id + '0' + current_ussd_session.national_shortcut
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

    return @race_header
  end

  def back_to_alr_bet_type
    alr_generic_race_header(@current_ussd_session)

    @rendered_text = %Q[PMU - ALR
#{@current_ussd_session.national_label} > #{@current_ussd_session.alr_bet_type_label}
#{@race_header}
1- Long champ
2- Champ réduit
3- Champ total
0- Retour
00- Accueil]
    @session_identifier = '32'
    @current_ussd_session.update_attributes(session_identifier: @session_identifier)
  end

  def back_to_alr_multi_selection
    alr_generic_race_header(@current_ussd_session)

    @rendered_text = %Q[PMU - ALR
#{@current_ussd_session.national_label} > #{@bet_type_label}
#{@race_header}
1- Multi 4/4
2- Multi 4/5
3- Multi 4/6
4- Multi 4/7
0- Retour
00- Accueil]
    @session_identifier = '33'
    @current_ussd_session.update_attributes(session_identifier: @session_identifier)
  end

  def back_to_alr_select_formula
    alr_generic_race_header(@current_ussd_session)

    @rendered_text = %Q[PMU - ALR
#{@current_ussd_session.national_label} > #{@current_ussd_session.alr_bet_type_label}
#{@race_header}
1- Long champ
2- Champ réduit
3- Champ total
0- Retour
00- Accueil]
    @session_identifier = '32'
    @current_ussd_session.update_attributes(session_identifier: @session_identifier)
  end

  def back_to_alr_select_base
    alr_generic_race_header(@current_ussd_session)

    @rendered_text = %Q[PMU - ALR
#{@current_ussd_session.national_label} > #{@current_ussd_session.alr_bet_type_label}
#{@race_header}
Saisissez le numero de votre cheval de BASE et utiliser X pour definir l'emplacement de votre selection
0- Retour
00- Accueil]
    @session_identifier = '34'
    @current_ussd_session.update_attributes(session_identifier: @session_identifier)
  end

  def back_to_alr_selection
    @rendered_text = %Q[PMU - ALR
#{@current_ussd_session.national_label} > #{@current_ussd_session.alr_bet_type_label}
#{@race_header}
Saisissez les numéros de vos chevaux séparés par un espace
0- Retour
00- Accueil]
    @session_identifier = '35'
    @current_ussd_session.update_attributes(session_identifier: @session_identifier)
  end

  def back_to_alr_full_formula
    @rendered_text = %Q[PMU - ALR
#{@current_ussd_session.national_label} > #{@current_ussd_session.alr_bet_type_label}
#{@race_header}
Voulez-vous jouer en formule complète?
1- Oui
2- Non
0- Retour
00- Accueil]
    @session_identifier = '36'
    @current_ussd_session.update_attributes(session_identifier: @session_identifier)
  end

  def back_to_alr_stake
    @rendered_text = %Q[PMU - ALR
Le pari n'a pas pu être évalué
#{@current_ussd_session.national_label} > #{@current_ussd_session.alr_bet_type_label}
#{@race_header}
Saisissez le nombre de fois
0- Retour
00- Accueil]
    @session_identifier = '37'
    @current_ussd_session.update_attributes(session_identifier: @session_identifier)
  end

  def back_list_games_menu
    @rendered_text = %Q[
1- Loto Bonheur
2- PMU ALR
3- PMU PLR
4- SPORTCASH
0- Retour
00- Accueil]
    @session_identifier = '11'
    @current_ussd_session.update_attributes(session_identifier: @session_identifier)
  end

  def back_to_get_paymoney_sold
    @rendered_text = %Q[Veuillez entrer votre code secret de jeu pour consulter votre solde.
1- Solde autre compte
0- Retour
00- Accueil]
    @session_identifier = '8'
    @current_ussd_session.update_attributes(session_identifier: @session_identifier)
  end

  def back_to_list_spc_main_menu
    @rendered_text = %Q[SPORTCASH
1- Sport
2- Top matchs
3- Dernière minute
4- Opportunités
5- Lives
6- Jouer
0- Retour
00- Accueil]
    @session_identifier = '49'
    @current_ussd_session.update_attributes(session_identifier: @session_identifier)
  end

  def back_to_list_spc_sports
    @list_sportcash_sports_request = Parameter.first.parionsdirect_url + "/ussd_spc/get_list_sport"
    @list_sportcash_sports_response = RestClient.get(@list_sportcash_sports_request) rescue ''
    sports_string = ""
    counter = 0

    sports = JSON.parse('{"sports":' + @list_sportcash_sports_response + '}') rescue nil
    sports = sports["sports"] rescue nil
    unless sports.blank?
      sports.each do |sport|
        counter += 1
        sports_string << counter.to_s + '- ' + %Q[#{sport["Description"]}
]
      end
    end
    @rendered_text = %Q[SPORTCASH - Liste des sports
#{sports_string}
0- Retour
00- Accueil]
    @session_identifier = '50'
    @current_ussd_session.update_attributes(session_identifier: @session_identifier)
  end

  def back_to_list_spc_tournaments
    @spc_event_list_request = Parameter.first.parionsdirect_url + "/ussd_spc/get_event_by_tourn_sport/#{@current_ussd_session.spc_sport_label}/#{@current_ussd_session.spc_tournament_code}"
    @spc_event_list_response = RestClient.get(@spc_event_list_request) rescue ''
      tournaments_string = ""
      counter = 0

      tournaments = JSON.parse('{"tournaments":' + @spc_tournament_list_response + '}') rescue nil
      tournaments = tournaments["tournaments"] rescue nil
      unless tournaments.blank?
        tournaments.each do |tournament|
          counter += 1
          tournaments_string << counter.to_s + '- ' + %Q[#{tournament["Descrition_Tourn"]}
  ]
        end
      end
      @rendered_text = %Q[SPORTCASH
#{tournaments_string}
0- Retour
00- Accueil]
    @session_identifier = '51'
    @current_ussd_session.update_attributes(session_identifier: @session_identifier)
  end

  def back_to_list_spc_events
    @spc_bet_type_request = Parameter.first.parionsdirect_url + "#{@current_ussd_session.spc_live == true ? '/ussd_spc/get_event_markets_live/' : '/ussd_spc/get_event_markets/'}#{@current_ussd_session.spc_event_code}"
    @spc_bet_type_response = RestClient.get(@spc_bet_type_request) #rescue ''
    @spc_event_list_request = Parameter.first.parionsdirect_url + "/ussd_spc/get_event_by_tourn_sport/#{@current_ussd_session.spc_sport_label}/#{@current_ussd_session.spc_tournament_code}"
    @spc_event_list_response = RestClient.get(@spc_event_list_request) #rescue ''
    events_string = ""
    counter = 0

    events = JSON.parse('{"events":' + @spc_event_list_response + '}') #rescue nil
    events = events["events"] #rescue nil
    unless events.blank?
      events.each do |event|
        counter += 1
        events_string << counter.to_s + '- ' + %Q[#{event["Description_match"]} (#{event["Palcode"]}-#{event["Codevts"]})
]
      end
    end
    @rendered_text = %Q[SPORTCASH
#{events_string}
0- Retour
00- Accueil]
    @session_identifier = '52'
    @current_ussd_session.update_attributes(session_identifier: @session_identifier)
  end

  def back_to_list_spc_bet_types
    @spc_bet_type_request = Parameter.first.parionsdirect_url + "#{@current_ussd_session.spc_live == true ? '/ussd_spc/get_event_markets_live/' : '/ussd_spc/get_event_markets/'}#{@current_ussd_session.spc_event_code}"
    @spc_bet_type_response = RestClient.get(@spc_bet_type_request) rescue ''
    bet_types_string = ""
    counter = 0

    bet_types = JSON.parse('{"bet_types":' + @spc_bet_type_response + '}') rescue nil
    bet_types = bet_types["bet_types"] rescue nil
    unless bet_types.blank?
      bet_types.each do |bet_type|
        counter += 1
        bet_types_string << counter.to_s + '- ' + %Q[#{bet_type["Bet_description"]}
]
      end
    end
    @rendered_text = %Q[#{@event[0] rescue ''}
Faites vos pronostics. Choisissez votre pari :
#{bet_types_string}
0- Retour
00- Accueil]
    @session_identifier = '53'
    @current_ussd_session.update_attributes(session_identifier: @session_identifier)
  end

  def back_to_get_paymoney_other_account_number
    @rendered_text = %Q[Veuillez entrer le numéro de compte de jeu dont vous voulez consulter le solde.
0- Retour
00- Accueil]
    @session_identifier = '39'
    @current_ussd_session.update_attributes(session_identifier: @session_identifier)
  end

  def back_to_get_paymoney_otp
    @rendered_text = %Q[Veuillez entrer votre code secret de jeu pour consulter votre liste d'OTP.
1- OTP autre compte
0- Retour
00- Accueil]
    @session_identifier = '8'
    @current_ussd_session.update_attributes(session_identifier: @session_identifier)
  end

  def main_menu
    @req_body = request.body.read
    @raw_body = @req_body.gsub("ns1:", "").gsub("ns2:", "") #rescue nil
    @received_body = Nokogiri.XML(@raw_body) #rescue nil
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

    UssdReceptionLog.create(received_parameters: @req_body, rev_id: @rev_id, rev_password: @rev_password, sp_id: @sp_id, service_id: @service_id, timestamp: @timestamp, trace_unique_id: @unique_id, msg_type: @msg_type, sender_cb: @sender_cb, receiver_cb: @receive_cb, ussd_of_type: @ussd_op_type, msisdn: @msisdn, service_code: @service_code, code_scheme: @code_scheme, ussd_string: @ussd_string, error_code: @error_code, error_message: @error_message, remote_ip: remote_ip_address)

    @account_profile = AccountProfile.find_by_msisdn(@msisdn[-8,8]) rescue nil

    render :xml => @result

    Thread.new do
      ActiveRecord::Base.connection_pool.with_connection do
        if @error_code == '0'
          # Récupération d'une session existante
          @current_ussd_session = UssdSession.find_by_sender_cb(@sender_cb)

          if @current_ussd_session.blank?
            if @account_profile.blank?
              display_mtn_welcome_menu
              UssdSession.create(session_identifier: @session_identifier, sender_cb: @sender_cb)
            else
              authenticate_or_create_parionsdirect_account(@msisdn)
              UssdSession.create(session_identifier: @session_identifier, sender_cb: @sender_cb, parionsdirect_password_url: @parionsdirect_password_url, parionsdirect_password_response: (@parionsdirect_password_response.body rescue 'ERR'), parionsdirect_password: @password, parionsdirect_salt: @salt)
            end
          else
            case @current_ussd_session.session_identifier
            when '-10'
              select_action_depending_on_mtn_menu_selection
              if @status
                case @ussd_string
                  when '1'
                    authenticate_or_create_parionsdirect_account(@msisdn)
                    @current_ussd_session.update_attributes(session_identifier: @session_identifier, parionsdirect_password_url: @parionsdirect_password_url, parionsdirect_password_response: (@parionsdirect_password_response.body rescue 'ERR'), parionsdirect_password: @password, parionsdirect_salt: @salt)
                  when '2'
                    display_mtn_terms_and_conditions
                    @current_ussd_session.update_attributes(session_identifier: @session_identifier)
                  when '3'
                    exit_menu(@sender_cb, "Merci d'utiliser MTN Mobile Money")
                end
              end
            when '-9'
              select_action_depending_on_mtn_terms_and_conditions_selection
              if @status
                case @ussd_string
                  when '0'
                    display_mtn_welcome_menu
                    @current_ussd_session.update_attributes(session_identifier: @session_identifier)
                  when '00'
                    exit_menu(@sender_cb, "Merci d'utiliser MTN Mobile Money")
                  else
                    display_mtn_terms_and_conditions
                    @current_ussd_session.update_attributes(session_identifier: @session_identifier)
                end
              end
            when '-11'
              select_action_depending_on_mtn_home_menu_terms_and_conditions_selection
              if @status
                case @ussd_string
                  when '0'
                    @rendered_text = %Q[BIENVENUE DANS LE MENU LONACI:
  1- Recharger compte de jeu
  2- Jouer
  3- Termes et conditions]
                    @session_identifier = '5--'
                    @current_ussd_session.update_attributes(session_identifier: @session_identifier)
                  when '00'
                    exit_menu(@sender_cb, "Merci d'utiliser MTN Mobile Money")
                  else
                    display_mtn_home_menu_terms_and_conditions
                    @current_ussd_session.update_attributes(session_identifier: @session_identifier)
                end
              end
            when '0'
              #authenticate_or_create_parionsdirect_account(@msisdn)
              #UssdSession.create(session_identifier: @session_identifier, sender_cb: @sender_cb)
            # Saisie du code secret de création de compte parionsdirect
            when '1'
              set_parionsdirect_password
              @current_ussd_session.update_attributes(session_identifier: @session_identifier, creation_pd_password: @creation_pd_password)
            # Saisie de la confirmation du code secret de création de compte parionsdirect
            when '3'
              create_parionsdirect_account
              @current_ussd_session.update_attributes(session_identifier: @session_identifier, creation_pd_password_confirmation: @creation_pd_password_confirmation, creation_pd_request: @creation_pd_request, creation_pd_response: (@creation_pd_response.body rescue 'ERR'), pd_account_created: @pd_account_created)
            when '2'
              check_parionsdirect_password
              @current_ussd_session.update_attributes(session_identifier: @session_identifier, connection_pd_pasword: @ussd_string)
            when '4'
              check_paymoney_account_number
              @current_ussd_session.update_attributes(session_identifier: @session_identifier, check_pw_account_url: @check_pw_account_url, check_pw_account_response: (@check_pw_account_response.body rescue 'ERR'), pw_account_number: @pw_account_number, pw_account_token: @pw_account_token)
            # Saisie du numéro de compte de jeu
            when '4-'
              create_paymoney_account
              @current_ussd_session.update_attributes(session_identifier: @session_identifier, creation_pw_request: @creation_pw_request, creation_pw_response: (@creation_pw_response.body rescue 'ERR'), pw_account_created: @pw_account_created)
              if @pw_account_created == true
                exit_menu(@sender_cb, "Vous allez recevoir un SMS avec les détails de votre portemonnaie de jeu.")
              end
            when '5--'
              select_action_depending_on_mtn_main_menu_selection
              if @status
                case @ussd_string
                  when '1'
                    reload_paymoney_with_mtn_money
                    @current_ussd_session.update_attributes(session_identifier: @session_identifier)
                  when '2'
                    display_parions_direct_gaming_chanels
                    @current_ussd_session.update_attributes(session_identifier: @session_identifier)
                  when '3'
                    display_mtn_home_menu_terms_and_conditions
                    @current_ussd_session.update_attributes(session_identifier: @session_identifier)
                end
              end
            when '6--'
              select_action_depending_on_mtn_gaming_channel_menu_selection
              if @status
                case @ussd_string
                  when '1'
                    display_parions_direct_main_ussd_menu
                    @current_ussd_session.update_attributes(session_identifier: @session_identifier)
                  when '2'
                    display_parions_direct_web_link
                    @current_ussd_session.update_attributes(session_identifier: @session_identifier)
                  when '3'
                    display_parions_direct_apk_link
                    @current_ussd_session.update_attributes(session_identifier: @session_identifier)
                  when '4'
                    display_parions_direct_windows_phone_link
                    @current_ussd_session.update_attributes(session_identifier: @session_identifier)
                end
              end
            when '7--'
              display_mtn_reload_instructions_depending_on_reloading_menu_selection
              if @status
                case @ussd_string
                  when '0'
                    back_list_main_menu
                  when '00'
                    back_list_main_menu
                  when '1'
                    enter_mtn_reload_amount
                  when '2'
                    enter_other_account_mtn_reload_account_number
                end
                unless ['0', '00'].include?(@ussd_string)
                  @current_ussd_session.update_attributes(session_identifier: @session_identifier)
                end
              end
            when '8--'
              get_reload_account
              @current_ussd_session.update_attributes(session_identifier: @session_identifier, reload_account: @ussd_string)
            when '9--'
              display_mtn_reload_amount_with_fee
              @current_ussd_session.update_attributes(session_identifier: @session_identifier, reload_amount: @ussd_string)
            when '9---'
              proceed_reloading
              @current_ussd_session.update_attributes(session_identifier: @session_identifier, reload_amount: @ussd_string, reload_request: @reload_request, reload_response: @reload_response)
            # Sélection d'un élément du menu
            when '8'
              # solde du compte de jeu
              get_paymoney_sold
              unless ['0', '00'].include?(@ussd_string)
                @current_ussd_session.update_attributes(session_identifier: @session_identifier, paymoney_sold_url: @get_paymoney_sold_url, paymoney_sold_response: (@get_paymoney_sold_response.body rescue nil))
              end
            when '9'
              # affichage de la liste des otp
              get_paymoney_otp
              unless ['0', '00'].include?(@ussd_string)
                @current_ussd_session.update_attributes(session_identifier: @session_identifier, paymoney_otp_url: @get_paymoney_otp_url, paymoney_otp_response: (@get_paymoney_otp_response.body rescue nil))
              end
            when '10'
              # retour au menu principal ou affichage des otp d'un autre compte
              list_otp_set_session_identifier
              unless ['0', '00'].include?(@ussd_string)
                @current_ussd_session.update_attributes(session_identifier: @session_identifier)
              end
            when '5'
              set_session_identifier_depending_on_menu_selected
              if @status
                case @ussd_string
                  when '1'
                    display_games_menu
                    @current_ussd_session.update_attributes(session_identifier: @session_identifier)
                  when '2'
                    display_bet_games_list
                    @current_ussd_session.update_attributes(session_identifier: @session_identifier)
                  when '3'
                    get_paymoney_password_to_check_sold
                    @current_ussd_session.update_attributes(session_identifier: @session_identifier)
                  when '4'
                    @rendered_text = %Q[1- Recharger mon compte
2- Recharger autre compte
0- Retour
00- Accueil]
                    @session_identifier = '7--'
                    @current_ussd_session.update_attributes(session_identifier: @session_identifier)
                  when '5'
                    display_sms_coming_soon
                    @current_ussd_session.update_attributes(session_identifier: @session_identifier)
                  when '6'
                    get_paymoney_password_to_check_otp
                    @current_ussd_session.update_attributes(session_identifier: @session_identifier)
                  when '7'
                    display_default_paymoney_account
                    @current_ussd_session.update_attributes(session_identifier: @session_identifier)
                  when '8'
                    enter_mtn_unload_amount
                    @current_ussd_session.update_attributes(session_identifier: @session_identifier)
                end
              end
            when '5---'
              return_from_display_sms_coming_soon
              @current_ussd_session.update_attributes(session_identifier: @session_identifier)
            when '10--'
              get_unload_amount
              @current_ussd_session.update_attributes(session_identifier: @session_identifier, unload_amount: @ussd_string)
            when '11--'
              proceed_unloading
              @current_ussd_session.update_attributes(session_identifier: @session_identifier, unload_request: @unload_request, unload_response: @unload_response)
            when '39'
              get_paymoney_other_account_number
              unless ['0', '00'].include?(@ussd_string)
                @current_ussd_session.update_attributes(session_identifier: @session_identifier, other_paymoney_account_number: @ussd_string)
              end
            when '40'
              get_paymoney_other_account_password
              unless ['0', '00'].include?(@ussd_string)
                @current_ussd_session.update_attributes(session_identifier: @session_identifier, other_paymoney_account_password: @ussd_string, paymoney_sold_url: @get_paymoney_sold_url, paymoney_sold_response: (@get_paymoney_sold_response.body rescue nil))
              end
            when '41'
              get_paymoney_other_otp_account_number
              unless ['0', '00'].include?(@ussd_string)
                @current_ussd_session.update_attributes(session_identifier: @session_identifier, other_otp_paymoney_account_number: @ussd_string)
              end
            when '42'
              get_paymoney_other_otp_account_password
              unless ['0', '00'].include?(@ussd_string)
                @current_ussd_session.update_attributes(session_identifier: @session_identifier, other_otp_paymoney_account_password: @ussd_string)
              end
            when '43'
              set_default_paymoney_account
              unless ['0', '00'].include?(@ussd_string)
                @current_ussd_session.update_attributes(session_identifier: @session_identifier)
              end
            when '44'
              set_session_identifier_depending_game_list_selected
              if @status
                case @ussd_string
                  when '0'
                    back_list_main_menu
                  when '00'
                    back_list_main_menu
                  when '1'
                    list_loto_bets
                  when '2'
                    list_alr_bets
                  when '3'
                    list_plr_bets
                  when '4'
                    list_sportcash_bets
                end
              end
              unless ['0', '00'].include?(@ussd_string)
                @current_ussd_session.update_attributes(session_identifier: @session_identifier, loto_bets_list_request: @loto_bets_list_request, loto_bets_list_request: @loto_bets_list_response, plr_bets_list_request: @plr_bets_list_request, plr_bets_list_request: @plr_bets_list_response, ale_bets_list_request: @alr_bets_list_request, alr_bets_list_request: @alr_bets_list_response, spc_bets_list_request: @spc_bets_list_request, spc_bets_list_request: @spc_bets_list_response)
              end
            when '45'
              return_to_games_bets_list
              @current_ussd_session.update_attributes(session_identifier: @session_identifier)
            when '46'
              return_to_games_bets_list
              @current_ussd_session.update_attributes(session_identifier: @session_identifier)
            when '47'
              return_to_games_bets_list
              @current_ussd_session.update_attributes(session_identifier: @session_identifier)
            when '48'
              return_to_games_bets_list
              @current_ussd_session.update_attributes(session_identifier: @session_identifier)
            # Affichage du menu listant les jeux
            when '11'
              set_session_identifier_depending_on_game_selected
              if @status
                case @ussd_string
                  when '0'
                    back_list_main_menu
                  when '00'
                    back_list_main_menu
                  when '1'
                    loto_display_draw_day
                    @current_ussd_session.update_attributes(session_identifier: @session_identifier)
                  when '2'
                    alr_display_races
                    @current_ussd_session.update_attributes(session_identifier: @session_identifier, alr_get_current_program_request: @alr_get_current_program_request, alr_get_current_program_response: @alr_get_current_program_response.body, alr_program_id: @alr_program_id, alr_program_date: @alr_program_date, alr_program_status: @alr_program_status, alr_race_ids: @alr_race_ids.to_s, alr_race_list_request: @alr_race_list_request, alr_race_list_response: @alr_race_list_response.body, race_data: @race_data.to_s)
                  when '3'
                    plr_get_reunion
                    @current_ussd_session.update_attributes(session_identifier: @session_identifier, get_plr_race_list_request: @get_plr_race_list_request, get_plr_race_list_response: @get_plr_race_list_response)
                  when '4'
                    sportcash_main_menu
                    @current_ussd_session.update_attributes(session_identifier: @session_identifier)
                end
              end
            # Choix du jour de tirage
            when '12'
              set_session_identifier_depending_on_draw_day_selected
              if @status
                reference_date = "01/01/#{Date.today.year} 19:00:00"
                case @ussd_string
                  when '0'
                    back_list_games_menu
                  when '00'
                    back_list_main_menu
                  when '1'
                    @draw_day_label = "Etoile #{(35 + DateTime.parse(reference_date).upto(DateTime.now).count(&:monday?)).to_s}"
                    @draw_day_shortcut = 'etoile'
                  when '2'
                    @draw_day_label = "Emergence #{(36 + DateTime.parse(reference_date).upto(DateTime.now).count(&:tuesday?)).to_s}"
                    @draw_day_shortcut = 'emergence'
                  when '3'
                    @draw_day_label = "Fortune #{(44 + DateTime.parse(reference_date).upto(DateTime.now).count(&:wednesday?)).to_s}"
                    @draw_day_shortcut = 'fortune'
                  when '4'
                    @draw_day_label = "Privilège #{(36 + DateTime.parse(reference_date).upto(DateTime.now).count(&:thursday?)).to_s}"
                    @draw_day_shortcut = 'privilege'
                  when '5'
                    @draw_day_label = "Solution #{(36 + DateTime.parse(reference_date).upto(DateTime.now).count(&:friday?)).to_s}"
                    @draw_day_shortcut = 'solution'
                  when '6'
                    @draw_day_label = "Diamant #{(45 + DateTime.parse(reference_date).upto(DateTime.now).count(&:saturday?)).to_s}"
                    @draw_day_shortcut = 'diamant'
                end
                unless ['0', '00'].include?(@ussd_string)
                  loto_display_bet_selection
                  @current_ussd_session.update_attributes(session_identifier: @session_identifier, draw_day_label: @draw_day_label, draw_day_shortcut: @draw_day_shortcut)
                end
              end
            # Choix de la sélection
            when '13'
              set_session_identifier_depending_on_bet_selection_selected
              if @status
                case @ussd_string
                  when '0'
                    back_display_loto_draw_day
                  when '00'
                    back_list_main_menu
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
                unless ['0', '00'].include?(@ussd_string)
                  loto_display_formula_selection
                  @current_ussd_session.update_attributes(session_identifier: @session_identifier, bet_selection: @bet_selection, bet_selection_shortcut: @bet_selection_shortcut)
                end
              end
            when '14'
              set_session_identifier_depending_on_formula_selected
              if @status
                case @ussd_string
                  when '0'
                    back_display_bet_selection
                  when '00'
                    back_list_main_menu
                  when '1'
                    @formula_label = "Simple"
                    @formula_shortcut = 'simple'
                    loto_bet_modifier = '0'
                  when '2'
                    @formula_label = "Perm"
                    @formula_shortcut = 'perm'
                    loto_bet_modifier = '0'
                  when '3'
                    @formula_label = "Champ réduit"
                    @formula_shortcut = 'champ_reduit'
                    loto_bet_modifier = '2'
                  when '4'
                    @formula_label = "Champ total"
                    @formula_shortcut = 'champ_total'
                    loto_bet_modifier = '1'
                end
                unless ['0', '00'].include?(@ussd_string)
                  loto_display_horse_selection_fields
                  @current_ussd_session.update_attributes(session_identifier: @session_identifier, formula_label: @formula_label, formula_shortcut: @formula_shortcut, loto_bet_modifier: loto_bet_modifier)
                end
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
              # Prise du pari à la saisie du code secret de jeu
              @account_profile = AccountProfile.find_by_msisdn(@msisdn[-8,8])
              loto_place_bet
              @current_ussd_session.update_attributes(session_identifier: @session_identifier, loto_bet_paymoney_password: @ussd_string, loto_place_bet_url: @loto_place_bet_url.to_s + @request_body.to_s, loto_place_bet_response: (@loto_place_bet_response.body rescue nil), get_gamer_id_request: @get_gamer_id_request, get_gamer_id_response: (@get_gamer_id_response.body rescue nil))
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
                  when '0'
                    back_to_plr_get_race
                  when '00'
                    back_list_main_menu
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
            when '22-'
              case @ussd_string
                when '0'
                  back_to_plr_get_race
                when '00'
                  back_list_main_menu
                else
                  display_plr_race_details
                end
            when '23'
              set_session_identifier_depending_on_plr_bet_type_selected
              if @status
                case @ussd_string
                  when '0'
                    back_to_plr_gaming_menu
                  when '00'
                    back_list_main_menu
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
                unless ['0', '00'].include?(@ussd_string)
                  @current_ussd_session.update_attributes(session_identifier: @session_identifier, plr_bet_type_label: @plr_bet_type_label, plr_bet_type_shortcut: @plr_bet_type_shortcut)
                end
              end
            when '24'
              set_session_identifier_depending_on_plr_formula_selected
              if @status
                case @ussd_string
                  when '0'
                    back_to_plr_bet_type
                  when '00'
                    back_list_main_menu
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
              unless ['0', '00'].include?(@ussd_string)
                @current_ussd_session.update_attributes(session_identifier: @session_identifier, plr_formula_label: @plr_formula_label, plr_formula_shortcut: @plr_formula_shortcut)
              end
            when '25'
              plr_selection_or_stake_depending_on_formula
              unless ['0', '00'].include?(@ussd_string)
                @current_ussd_session.update_attributes(session_identifier: @session_identifier, plr_base: @ussd_string)
              end
            # PLR, sélectionner le nombre de fois
            when '26'
              plr_select_number_of_times
              unless ['0', '00'].include?(@ussd_string)
                @current_ussd_session.update_attributes(session_identifier: @session_identifier, plr_selection: @ussd_string)
              end
            when '27'
              plr_evaluate_bet
              unless ['0', '00'].include?(@ussd_string)
                @current_ussd_session.update_attributes(session_identifier: @session_identifier, plr_number_of_times: @ussd_string, plr_evaluate_bet_request: @plr_evaluate_bet_request + @request_body, plr_evaluate_bet_response: @plr_evaluate_bet_response, bet_cost_amount: @bet_cost_amount)
              end
            when '28'
              @account_profile = AccountProfile.find_by_msisdn(@msisdn[-8,8])
              plr_place_bet
              unless ['0', '00'].include?(@ussd_string)
                @current_ussd_session.update_attributes(session_identifier: @session_identifier, plr_number_of_times: @plr_number_of_times, plr_place_bet_request: @plr_place_bet_request + @body, plr_place_bet_response: @plr_place_bet_response.body)
              end
            when '30'
              alr_display_bet_type
              unless ['0', '00'].include?(@ussd_string)
                @current_ussd_session.update_attributes(session_identifier: @session_identifier, national_label: @national_label, national_shortcut: @national_shortcut, alr_bet_type_menu: @alr_bet_type_menu)
              end
            when '31'
              alr_display_formula
              unless ['0', '00'].include?(@ussd_string)
                @current_ussd_session.update_attributes(session_identifier: @session_identifier, alr_bet_type_label: @bet_type_label, alr_bet_id: @alr_bet_id)
              end
            when '32'
              set_session_identifier_depending_on_alr_bet_type_selected
              if @status
                case @ussd_string
                  when '0'
                    back_to_alr_display_formula
                  when '00'
                    back_list_main_menu
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
              unless ['0', '00'].include?(@ussd_string)
                @current_ussd_session.update_attributes(session_identifier: @session_identifier, alr_formula_label: alr_formula_label, alr_formula_shortcut: alr_formula_shortcut)
              end
            when '33'
              set_session_identifier_depending_on_alr_multi_selected
              if @status
                case @ussd_string
                  when '0'
                    back_to_alr_display_formula
                  when '00'
                    back_list_main_menu
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
              unless ['0', '00'].include?(@ussd_string)
                @current_ussd_session.update_attributes(session_identifier: @session_identifier, alr_formula_label: alr_formula_label, alr_formula_shortcut: alr_formula_shortcut)
              end
            when '34'
              validate_alr_base
              unless ['0', '00'].include?(@ussd_string)
                @current_ussd_session.update_attributes(session_identifier: @session_identifier, alr_base: @ussd_string)
              end
            when '35'
              validate_alr_horses
              unless ['0', '00'].include?(@ussd_string)
                @current_ussd_session.update_attributes(session_identifier: @session_identifier, alr_selection: @ussd_string)
              end
            when '36'
              alr_set_full_formula
              unless ['0', '00'].include?(@ussd_string)
                @current_ussd_session.update_attributes(session_identifier: @session_identifier, full_formula: @full_formula)
              end
            when '37'
              alr_evaluate_bet
              unless ['0', '00'].include?(@ussd_string)
                @current_ussd_session.update_attributes(session_identifier: @session_identifier, alr_stake: @ussd_string, alr_evaluate_bet_request: @alr_evaluate_bet_request + @body, alr_evaluate_bet_response: @alr_evaluate_bet_response.body, alr_scratched_list: @alr_scratched_list.to_s, alr_combinations: @alr_combinations.to_s, alr_amount: @alr_amount)
              end
            when '38'
              @account_profile = AccountProfile.find_by_msisdn(@msisdn[-8,8])
              alr_place_bet
              unless ['0', '00'].include?(@ussd_string)
                @current_ussd_session.update_attributes(session_identifier: @session_identifier, alr_place_bet_request: @alr_place_bet_request + @body, alr_place_bet_response: @alr_place_bet_response.body, get_gamer_id_request: @get_gamer_id_request, get_gamer_id_response: @get_gamer_id_response.body)
              end
            when '49'
              set_session_identifier_sportcash_main_menu_selected
              if @status
                case @ussd_string
                  when '0'
                    back_list_games_menu
                  when '00'
                    back_list_main_menu
                  when '1'
                    list_sportcash_sports
                  when '2'
                    spc_top_match
                    @current_ussd_session.update_attributes(session_identifier: @session_identifier, events_trash: @events_trash, spc_event_list_request: @spc_event_list_request, spc_event_list_response: @spc_event_list_response)
                  when '3'
                    spc_last_minute_match
                    @current_ussd_session.update_attributes(session_identifier: @session_identifier, events_trash: @events_trash, spc_event_list_request: @spc_event_list_request, spc_event_list_response: @spc_event_list_response)
                  when '4'
                    spc_list_opportunities
                    @current_ussd_session.update_attributes(session_identifier: @session_identifier, opportunities_trash: @opportunities_trash, spc_opportunities_list_request: @spc_opportunities_list_request, spc_opportunities_list_response: @spc_opportunities_list_response)
                  when '5'
                    spc_live_match
                    @current_ussd_session.update_attributes(session_identifier: @session_identifier, events_trash: @events_trash, spc_event_list_request: @spc_event_list_request, spc_event_list_response: @spc_event_list_response, spc_live: @spc_live)
                  when '6'
                    spc_get_event_code
                    @current_ussd_session.update_attributes(session_identifier: @session_identifier)
                end
              end
              @current_ussd_session.update_attributes(session_identifier: @session_identifier, list_sportcash_sports_request: @list_sportcash_sports_request, list_sportcash_sports_response: @list_sportcash_sports_response, list_spc_sport: @sports_trash)
            when '52-'
              spc_list_opportunities_details
              @current_ussd_session.update_attributes(session_identifier: @session_identifier, spc_combined: @spc_combined, spc_combined_string: @spc_combined_string)
            when '49-'
              spc_play
              @current_ussd_session.update_attributes(session_identifier: @session_identifier, spc_bet_type_trash: @bet_types_trash, spc_bet_type_request: @spc_bet_type_request, spc_bet_type_response: @spc_bet_type_response, spc_event_description: @spc_event_description, spc_event_pal_code: @spc_event_pal_code, spc_event_code: @spc_event_code, spc_event_date: @spc_event_date, spc_event_time: @spc_event_time)
            when '50'
              set_session_identifier_depending_on_spc_sports_list_selected
              @current_ussd_session.update_attributes(session_identifier: @session_identifier, tournaments_trash: @tournaments_trash, spc_tournament_list_request: @spc_tournament_list_request, spc_tournament_list_response: @spc_tournament_list_response, spc_sport_label: (@sport_name[0] rescue nil), spc_sport_code: (@sport_name[1] rescue nil))
            when '51'
              set_session_identifier_depending_on_spc_sport_selected
              @current_ussd_session.update_attributes(session_identifier: @session_identifier, events_trash: @events_trash, spc_event_list_request: @spc_event_list_request, spc_event_list_response: @spc_event_list_response, spc_tournament_label: (@tournament[0] rescue nil), spc_tournament_code: (@tournament[1] rescue nil))
            when '52'
              set_session_identifier_depending_on_spc_event_selected
              @current_ussd_session.update_attributes(session_identifier: @session_identifier, spc_bet_type_trash: @bet_types_trash, spc_bet_type_request: @spc_bet_type_request, spc_bet_type_response: @spc_bet_type_response, spc_event_description: (@event[0] rescue nil), spc_event_pal_code: (@event[1] rescue nil), spc_event_code: (@event[2] rescue nil), spc_event_date: (@event[3] rescue nil), spc_event_time: (@event[4] rescue nil))
            when '53'
              set_session_identifier_depending_on_bet_type_selected
              @current_ussd_session.update_attributes(session_identifier: @session_identifier, spc_draw_trash: @draw_trash, spc_draw_request: @spc_draw_request, spc_draw_response: @spc_draw_response, spc_bet_description: (@bet_type[1] rescue nil), spc_bet_code: (@bet_type[0] rescue nil))
            when '54'
              set_session_identifier_depending_on_spc_draw_selected
              @current_ussd_session.update_attributes(session_identifier: @session_identifier, spc_draw_description: @spc_draw_description, spc_odd: @spc_odd)
            when '55'
              spc_validate_stake
              @current_ussd_session.update_attributes(session_identifier: @session_identifier, spc_stake: @spc_stake)
            when '56'
              @account_profile = AccountProfile.find_by_msisdn(@msisdn[-8,8])
              spc_place_bet
              @current_ussd_session.update_attributes(session_identifier: @session_identifier, spc_place_bet_request: @spc_place_bet_url + @request_body, spc_place_bet_response: @spc_place_bet_response.body)
            end
          end
          unless @exit == true
            send_ussd(@operation_type, @msisdn, @sender_cb, @linkid, @rendered_text)
          end
        end
      end
    #ensure
    end

    #render text: @rendered_text
  end

  def display_sms_coming_soon
    @rendered_text = %Q[Bientôt disponible
0- Retour
00- Accueil]
    @session_identifier = '5---'
  end

  def return_from_display_sms_coming_soon
    if @ussd_string == '00'
      back_list_main_menu
    else
      @rendered_text = %Q[
1- Jeux
2- Mes paris
3- Mon solde
4- Rechargement
5- Votre service SMS
6- Mes OTP
7- Mes comptes
8- Retrait vers MTN MOBILE MONEY]
      @session_identifier = '5'
    end
  end

  def display_mtn_welcome_menu
    @rendered_text = %Q[BIENVENUE DANS LE MENU LONACI:
En continuant le processus, vous certifiez avoir +18 ans
1- Continuez
2- Voir termes et conditions
3- Quitter]
    @session_identifier = '-10'
  end

  def select_action_depending_on_mtn_menu_selection
    @status = false
    if ['1', '2', '3'].include?(@ussd_string)
      @status = true
    else
      @rendered_text = %Q[BIENVENUE DANS LE MENU LONACI:
En continuant le processus, vous certifiez avoir +18 ans
1- Continuez
2- Voir termes et conditions
3- Quitter]
      @session_identifier = '-10'
    end
  end

  def select_action_depending_on_mtn_terms_and_conditions_selection
    @status = false
    if ['0', '00'].include?(@ussd_string)
      @status = true
    else
      @rendered_text = %Q[LONACI-TERMES ET CONDITIONS

0- Retour
00- Quitter]
    @session_identifier = '-9'
    end
  end

  def select_action_depending_on_mtn_home_menu_terms_and_conditions_selection
    @status = false
    if ['0', '00'].include?(@ussd_string)
      @status = true
    else
      @rendered_text = %Q[LONACI-TERMES ET CONDITIONS

0- Retour
00- Quitter]
      @session_identifier = '-11'
    end
  end

  def display_mtn_terms_and_conditions
    @rendered_text = %Q[LONACI-TERMES ET CONDITIONS

0- Retour
00- Quitter]
    @session_identifier = '-9'
  end

  def display_mtn_home_menu_terms_and_conditions
    @rendered_text = %Q[LONACI-TERMES ET CONDITIONS

0- Retour
00- Quitter]
    @session_identifier = '-11'
  end

  def set_session_identifier_depending_on_menu_selected
    @status = false
    if ['1', '2', '3', '4', '5', '6', '7', '8'].include?(@ussd_string)
      @status = true
    else
      @rendered_text = %Q[
1- Jeux
2- Mes paris
3- Mon solde
4- Rechargement
5- Votre service SMS
6- Mes OTP
7- Mes comptes
8- Retrait vers MTN MOBILE MONEY]
      @session_identifier = '5'
    end
  end

  def select_action_depending_on_mtn_main_menu_selection
    @status = false
    if ['1', '2', '3'].include?(@ussd_string)
      @status = true
    else
      @rendered_text = %Q[BIENVENUE DANS LE MENU LONACI:
1- Recharger compte de jeu
2- Jouer
3- Termes et conditions]
      @session_identifier = '5--'
    end
  end

  def select_action_depending_on_mtn_gaming_channel_menu_selection
    @status = false
    if ['1', '2', '3', '4'].include?(@ussd_string)
      @status = true
    else
      @rendered_text = %Q[Choisissez votre canal de jeux
1- USSD
2- WEB
3- ANDROID
4- WINDOWS]
      @session_identifier = '6--'
    end
  end

  def display_mtn_reload_instructions_depending_on_reloading_menu_selection
    @status = false
    if ['1', '2', '0', '00'].include?(@ussd_string)
      @status = true
    else
      @rendered_text = %Q[1- Recharger mon compte
2- Recharger autre compte
0- Retour
00- Accueil]
      @session_identifier = '7--'
    end
  end

  def set_session_identifier_depending_on_draw_day_selected
    @status = false
    if ['1', '2', '3', '4', '5', '6', '0', '00'].include?(@ussd_string)
      @status = true
    else
      reference_date = "01/01/#{Date.today.year} 19:00:00"
      @rendered_text = %Q[
1- Etoile #{(35 + DateTime.parse(reference_date).upto(DateTime.now).count(&:monday?)).to_s}
2- Emergence #{(36 + DateTime.parse(reference_date).upto(DateTime.now).count(&:tuesday?)).to_s}
3- Fortune #{(44 + DateTime.parse(reference_date).upto(DateTime.now).count(&:wednesday?)).to_s}
4- Privilège #{(36 + DateTime.parse(reference_date).upto(DateTime.now).count(&:thursday?)).to_s}
5- Solution #{(36 + DateTime.parse(reference_date).upto(DateTime.now).count(&:friday?)).to_s}
6- Diamant #{(45 + DateTime.parse(reference_date).upto(DateTime.now).count(&:saturday?)).to_s}
0- Retour
00- Accueil]
      @session_identifier = '12'
    end
  end

  def list_loto_bets
    @loto_bets_list_request = Parameter.first.gateway_url + "/ail/loto/ussd/064482ec4/gamer/bets/list/#{@msisdn[-8,8]}"
    @loto_bets_list_response = RestClient.get(@loto_bets_list_request) rescue nil
    bets_string = ""

    bets = JSON.parse(@loto_bets_list_response) rescue nil
    bets = bets["bets"] rescue nil
    unless bets.blank?
      bets.each do |bet|
        bets_string << %Q{Statut: #{bet["bet_status"]} - N° ticket: #{bet["ticket_number"]} - N° ref.: #{bet["ref_number"]}
}
      end
    end

    @rendered_text = %Q[Loto Bonheur
Liste des paris
#{bets_string}
0- Retour
00- Accueil]
    @session_identifier = '45'
  end

  def list_plr_bets
    @plr_bets_list_request = Parameter.first.gateway_url + "/ail/pmu/ussd/064582ec4/gamer/bets/list/#{@msisdn[-8,8]}"
    @plr_bets_list_response = RestClient.get(@plr_bets_list_request) rescue nil
    bets_string = ""

    bets = JSON.parse(@plr_bets_list_response) rescue nil
    bets = bets["bets"] rescue nil
    unless bets.blank?
      bets.each do |bet|
        bets_string << %Q{Statut: #{bet["bet_status"]} - N° ticket: #{bet["ticket_number"]} - N° ref.: #{bet["ref_number"]}
}
      end
    end

    @rendered_text = %Q[PMU PLR
Liste des paris
#{bets_string}
0- Retour
00- Accueil]
    @session_identifier = '46'
  end

  def list_alr_bets
    @alr_bets_list_request = Parameter.first.gateway_url + "/ail/pmu_alr/ussd/064582ec2/gamer/bets/list/#{@msisdn[-8,8]}"
    @alr_bets_list_response = RestClient.get(@alr_bets_list_request) rescue nil
    bets_string = ""

    bets = JSON.parse(@alr_bets_list_response) rescue nil
    bets = bets["bets"] rescue nil
    unless bets.blank?
      bets.each do |bet|
        bets_string << %Q{Statut: #{bet["bet_status"]} - N° ticket: #{bet["serial_number"]}
}
      end
    end

    @rendered_text = %Q[PMU ALR
Liste des paris
#{bets_string}
0- Retour
00- Accueil]
    @session_identifier = '47'
  end

  def list_sportcash_bets
    @spc_bets_list_request = Parameter.first.gateway_url + "/ail/sportcash/ussd/064582ec8/gamer/bets/list/#{@msisdn[-8,8]}"
    @spc_bets_list_response = RestClient.get(@spc_bets_list_request) rescue nil
    bets_string = ""

    bets = JSON.parse(@spc_bets_list_response) rescue nil
    bets = bets["bets"] rescue nil
    unless bets.blank?
      bets.each do |bet|
        bets_string << %Q{Statut: #{bet["bet_status"]} - N° ticket: #{bet["ticket_id"]}
}
      end
    end

    @rendered_text = %Q[SPORTCASH
Liste des paris
#{bets_string}
0- Retour
00- Accueil]
    @session_identifier = '48'
  end

  def set_session_identifier_depending_on_bet_selection_selected
    @status = false
    if ['1', '2', '3', '4', '5', '0', '00'].include?(@ussd_string)
      @status = true
    else
      @rendered_text = %Q[Loto Bonheur
#{@current_ussd_session.draw_day_label}
1- PN - 1 numéro
2- 2N - 2 numéro
3- 3N - 3 numéro
4- 4N - 4 numéro
5- 5N - 5 numéro
0- Retour
00- Accueil]
      @session_identifier = '13'
    end
  end

  def set_session_identifier_depending_on_formula_selected
    @status = false
    if ['1', '2', '3', '4', '0', '00'].include?(@ussd_string)
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
      @rendered_text << %Q[
0- Retour
00- Accueil]
      @session_identifier = '14'
    end
  end

  def loto_display_bet_selection
    @rendered_text = %Q[#{@draw_day_label}
1- PN - 1 numéro
2- 2N - 2 numéro
3- 3N - 3 numéro
4- 4N - 4 numéro
5- 5N - 5 numéro
0- Retour
00- Accueil]
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
    @rendered_text << %Q[
0- Retour
00- Accueil]
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
    @rendered_text << %Q[
0- Retour
00- Accueil]
  end

  def loto_check_base_numbers
    @current_ussd_session = @current_ussd_session
    @ussd_string = @ussd_string
    case @ussd_string
      when '0'
        back_display_formula_selection
      when '00'
        back_list_main_menu
      else
        if base_numbers_overflow || invalid_base_numbers_range
          @rendered_text = %Q[#{@error_message}
Loto bonheur - #{@current_ussd_session.draw_day_label} #{@current_ussd_session.bet_selection} #{@formula_label}
#{@current_ussd_session.bet_selection == 'PN' ? 'Saisissez votre numéro' : "Saisissez vos numéros séparés d'un espace"} (Entre 1 et 90)
Veuillez entrer votre base.
0- Retour
00- Accueil]
          @session_identifier = '15'
        else
          if @current_ussd_session.formula_label != 'Champ total'
            @rendered_text = %Q[Loto bonheur - #{@current_ussd_session.draw_day_label} #{@current_ussd_session.bet_selection} #{@formula_label}
Base: #{@ussd_string}
#{@current_ussd_session.bet_selection == 'PN' ? 'Saisissez votre numéro' : "Saisissez vos numéros séparés d'un espace"} (Entre 1 et 90)
Veuillez entrer votre sélection.
0- Retour
00- Accueil]
            @session_identifier = '16'
          else
            @rendered_text = %Q[Loto bonheur - #{@current_ussd_session.draw_day_label} #{@current_ussd_session.bet_selection} #{@formula_label}
Base: #{@ussd_string}
#{@current_ussd_session.bet_selection == 'PN' ? 'Saisissez votre numéro' : "Saisissez vos numéros séparés d'un espace"} (Entre 1 et 90)

Veuillez entrer votre mise de base.
0- Retour
00- Accueil]
            @session_identifier = '17'
          end
        end
    end
  end

  def loto_check_selection_numbers
    @current_ussd_session = @current_ussd_session
    @ussd_string = @ussd_string
    case @ussd_string
      when '0'
        if @current_ussd_session.formula_label != 'Simple' && @current_ussd_session.formula_label != 'Perm'
          back_display_base_selection
        else
          back_display_formula_selection
        end
      when '00'
        back_list_main_menu
      else
        if selection_numbers_overflow || invalid_selection_numbers_range
          @rendered_text = %Q[#{@error_message}
Loto bonheur - #{@current_ussd_session.draw_day_label} #{@current_ussd_session.bet_selection} #{@current_ussd_session.formula_label}
 #{!@current_ussd_session.base_field.blank? ? "Base: " + @current_ussd_session.base_field : ""}
 #{@current_ussd_session.bet_selection == 'PN' ? 'Saisissez votre numéro' : "Saisissez vos numéros séparés d'un espace"} (Entre 1 et 90)
Veuillez entrer votre sélection.
0- Retour
00- Accueil]
          @session_identifier = '16'
        else
          @rendered_text = %Q[Loto bonheur - #{@current_ussd_session.draw_day_label} #{@current_ussd_session.bet_selection} #{@current_ussd_session.formula_label}
#{!@current_ussd_session.base_field.blank? ? "Base: " + @current_ussd_session.base_field : ""}
Sélection: #{@ussd_string}
Veuillez entrer votre mise de base.
0- Retour
00- Accueil]
          @selection_field = @ussd_string
          @session_identifier = '17'
        end
      end
  end

  def loto_evaluate_bet
    @current_ussd_session = @current_ussd_session
    @ussd_string = @ussd_string
    case @ussd_string
      when '0'
        back_display_selection
      when '00'
        back_list_main_menu
      else
        if @ussd_string.blank? || not_a_number?(@ussd_string)
          @rendered_text = %Q[Veuillez entrer une mise de base valide
Loto bonheur - #{@current_ussd_session.draw_day_label} #{@current_ussd_session.bet_selection} #{@current_ussd_session.formula_label}
#{!@current_ussd_session.base_field.blank? ? "Base: " + @current_ussd_session.base_field : ""}
#{!@current_ussd_session.selection_field.blank? ? "Sélection: " + @current_ussd_session.selection_field : ""}
Veuillez entrer votre mise de base.
0- Retour
00- Accueil]
          @session_identifier = '17'
        else
          set_repeats
          @repeats = @repeats
          if @repeats > 100000 || @repeats < 100
            @rendered_text = %Q[Votre pari est estimé à: #{@repeats} FCFA. Le montant de votre pari doit être compris entre 100 et 100 000 FCFA.
Loto bonheur - #{@current_ussd_session.draw_day_label} #{@current_ussd_session.bet_selection} #{@current_ussd_session.formula_label}
#{!@current_ussd_session.base_field.blank? ? "Base: " + @current_ussd_session.base_field : ""}
#{!@current_ussd_session.selection_field.blank? ? "Sélection: " + @current_ussd_session.selection_field : ""}
Veuillez entrer votre mise de base.
0- Retour
00- Accueil]
            @session_identifier = '17'
          else
            @rendered_text = %Q[Vous vous appretez à prendre un pari: #{@current_ussd_session.draw_day_label} #{@current_ussd_session.bet_selection} #{@current_ussd_session.formula_label}
#{!@current_ussd_session.base_field.blank? ? "Base: " + @current_ussd_session.base_field : ""}
#{!@current_ussd_session.selection_field.blank? ? "Sélection: " + @current_ussd_session.selection_field : ""}
Montant débité: #{@repeats} FCFA. Confirmez en saisissant votre code secret de jeu.
0- Retour
00- Accueil]
            @session_identifier = '18'
          end
        end
      end
  end

  def loto_place_bet
    @current_ussd_session = @current_ussd_session
    case @ussd_string
      when '0'
        back_evaluate_bet
      when '00'
        back_list_main_menu
      else
        if @ussd_string.length != 4 || not_a_number?(@ussd_string)
          @rendered_text = %Q[Veuillez entrer un code de jeu valide
Vous vous appretez à prendre un pari: #{@current_ussd_session.draw_day_label} #{@current_ussd_session.bet_selection} #{@current_ussd_session.formula_label}
#{!@current_ussd_session.base_field.blank? ? "Base: " + @current_ussd_session.base_field : ""}
#{!@current_ussd_session.selection_field.blank? ? "Sélection: " + @current_ussd_session.selection_field : ""}
Montant débité: #{@current_ussd_session.stake.split('-')[1]} FCFA. Confirmez en saisissant votre code secret de jeu.
0- Retour
00- Accueil]
          @session_identifier = '18'
        else
          @get_gamer_id_request = Parameter.first.gateway_url + "/8ba869a7a9c59f3a0/api/users/gamer_id/#{@account_profile.msisdn}"
          @get_gamer_id_response = Typhoeus.get(@get_gamer_id_request, connecttimeout: 30)
          if @get_gamer_id_response.body.blank?
            @rendered_text = %Q[Votre identifiant parieur n'a pas pu être récupéré.
Vous vous appretez à prendre un pari: #{@current_ussd_session.draw_day_label} #{@current_ussd_session.bet_selection} #{@current_ussd_session.formula_label}
#{!@current_ussd_session.base_field.blank? ? "Base: " + @current_ussd_session.base_field : ""}
#{!@current_ussd_session.selection_field.blank? ? "Sélection: " + @current_ussd_session.selection_field : ""}
Montant débité: #{@current_ussd_session.stake.split('-')[1]} FCFA. Confirmez en saisissant votre code secret de jeu.
0- Retour
00- Accueil]
            @session_identifier = '18'
          else
            @loto_place_bet_url = Parameter.first.gateway_url + "/ail/loto/api/96455396dc/bet/place/#{@get_gamer_id_response.body}/#{@account_profile.paymoney_account_number}/#{@ussd_string}"
            set_place_loto_bet_request_parameters
            @request_body = %Q[
                      {
                        "bet_code":"#{@bet_code}",
                        "bet_modifier":"#{@current_ussd_session.loto_bet_modifier}",
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
Montant débité: #{@current_ussd_session.stake.split('-')[1]} FCFA. Confirmez en saisissant votre code secret de jeu.
0- Retour
00- Accueil]
              @session_identifier = '18'
            else
              if json_object["error"].blank?
                reference_date = "01/01/#{Date.today.year} 19:00:00"
                @rendered_text = %Q[FELICITATIONS, votre pari a bien été  enregistré. N° ticket : #{json_object["bet"]["ticket_number"]} / Réf. : #{json_object["bet"]["ref_number"]}
Consultez les résultats le #{@end_date}
1- Etoile #{(35 + DateTime.parse(reference_date).upto(DateTime.now).count(&:monday?)).to_s}
2- Emergence #{(36 + DateTime.parse(reference_date).upto(DateTime.now).count(&:tuesday?)).to_s}
3- Fortune #{(44 + DateTime.parse(reference_date).upto(DateTime.now).count(&:wednesday?)).to_s}
4- Privilège #{(36 + DateTime.parse(reference_date).upto(DateTime.now).count(&:thursday?)).to_s}
5- Solution #{(36 + DateTime.parse(reference_date).upto(DateTime.now).count(&:friday?)).to_s}
6- Diamant #{(45 + DateTime.parse(reference_date).upto(DateTime.now).count(&:saturday?)).to_s}
0- Retour
00- Accueil]
                @session_identifier = '12'
              else
                @rendered_text = %Q[Votre pari n'a pas pu etre placé.
Vous vous appretez à prendre un pari: #{@current_ussd_session.draw_day_label} #{@current_ussd_session.bet_selection} #{@current_ussd_session.formula_label}
#{!@current_ussd_session.base_field.blank? ? "Base: " + @current_ussd_session.base_field : ""}
#{!@current_ussd_session.selection_field.blank? ? "Sélection: " + @current_ussd_session.selection_field : ""}
Montant débité: #{@current_ussd_session.stake.split('-')[1]} FCFA. Confirmez en saisissant votre code secret de jeu.
0- Retour
00- Accueil]
                @session_identifier = '18'
              end
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
4- SPORTCASH
0- Retour
00- Accueil]
    @session_identifier = '11'
  end

  def display_bet_games_list
    @rendered_text = %Q[Mes paris
1- Loto Bonheur
2- PMU ALR
3- PMU PLR
4- SPORTCASH
0- Retour
00- Accueil]
    @session_identifier = '44'
  end

  def return_to_games_bets_list
    if @ussd_string == '0'
      @rendered_text = %Q[Mes paris
1- Loto Bonheur
2- PMU ALR
3- PMU PLR
4- SPORTCASH
0- Retour
00- Accueil]
      @session_identifier = '44'
    else
      @rendered_text = %Q[
1- Jeux
2- Mes paris
3- Mon solde
4- Rechargement
5- Votre service SMS
6- Mes OTP
7- Mes comptes
8- Retrait vers MTN MOBILE MONEY]
      @session_identifier = '5'
    end
  end

  def set_session_identifier_depending_game_list_selected
    @status = false
    if ['1', '2', '3', '4', '0', '00'].include?(@ussd_string)
      @status = true
    else
      @rendered_text = %Q[Mes paris
1- Loto Bonheur
2- PMU ALR
3- PMU PLR
4- SPORTCASH
0- Retour
00- Accueil]
    @session_identifier = '44'
    end
  end

  def set_session_identifier_depending_on_game_selected
    @status = false
    if ['1', '2', '3', '4', '0', '00'].include?(@ussd_string)
      @status = true
    else
      @rendered_text = %Q[
1- Loto Bonheur
2- PMU ALR
3- PMU PLR
4- SPORTCASH
0- Retour
00- Accueil]
      @session_identifier = '11'
    end
  end

  def loto_display_draw_day
    reference_date = "01/01/#{Date.today.year} 19:00:00"
    @rendered_text = %Q[
1- Etoile #{(35 + DateTime.parse(reference_date).upto(DateTime.now).count(&:monday?)).to_s}
2- Emergence #{(36 + DateTime.parse(reference_date).upto(DateTime.now).count(&:tuesday?)).to_s}
3- Fortune #{(44 + DateTime.parse(reference_date).upto(DateTime.now).count(&:wednesday?)).to_s}
4- Privilège #{(36 + DateTime.parse(reference_date).upto(DateTime.now).count(&:thursday?)).to_s}
5- Solution #{(36 + DateTime.parse(reference_date).upto(DateTime.now).count(&:friday?)).to_s}
6- Diamant #{(45 + DateTime.parse(reference_date).upto(DateTime.now).count(&:saturday?)).to_s}
0- Retour
00- Accueil]
    @session_identifier = '12'
  end

  def get_paymoney_password_to_check_sold
    @rendered_text = %Q[Veuillez entrer votre code secret de jeu pour consulter votre solde.
1- Solde autre compte
0- Retour
00- Accueil]
    @session_identifier = '8'
  end

  def get_paymoney_password_to_check_otp
    @rendered_text = %Q[Veuillez entrer votre code secret de jeu pour consulter votre liste d'OTP.
1- OTP autre compte
0- Retour
00- Accueil]
    @session_identifier = '9'
  end

  def get_paymoney_otp
    case @ussd_string
      when '0'
        back_to_home
      when '00'
        back_to_home
      else
        if @ussd_string == '1'
          @rendered_text = %Q[Veuillez entrer le numéro de compte de jeu dont vous souhaitez consulter les OTP.
0- Retour
00- Accueil]
          @session_identifier = '41'
        else
          if @ussd_string.blank?
            @rendered_text = %Q[Veuillez entrer votre code secret de jeu pour consulter votre liste d'OTP.
1- OTP autre compte
0- Retour
00- Accueil]
            @session_identifier = '8'
          else
            account_profile = AccountProfile.find_by_msisdn(@msisdn[-8,8])
            @get_paymoney_otp_url = Parameter.first.paymoney_url + "/PAYMONEY_WALLET/rest/getLastOtp/#{account_profile.paymoney_account_number}/#{@ussd_string}/"
            @get_paymoney_otp_response = Typhoeus.get(@get_paymoney_otp_url, connecttimeout: 30)

            otps = %Q[{"otps":] + (@get_paymoney_otp_response.body rescue nil) + %Q[}]
            otps = JSON.parse(otps)["otps"] rescue nil

            if otps.blank?
              @rendered_text = %Q[Votre liste d'OTP est vide
1- OTP autre compte
0- Retour
00- Accueil]
              @session_identifier = '10'
            else
              otp_string = ""
              otps.each do |otp|
                t = Time.at(((otp["otpDate"].to_s)[0..9]).to_i)
                otp_string << otp["otpPin"] + ' ' + (otp["otpStatus"] == true ? 'Valide' : 'Désactivé') + t.strftime(" %d-%m-%Y ") + t.strftime("%Hh %Mmn") + %Q[
]
              end
              @rendered_text = %Q[#{otp_string}
1- OTP autre compte
0- Retour
00- Accueil]
              @session_identifier = '10'
            end
          end
        end
      end
  end

  def display_default_paymoney_account
    @rendered_text = %Q[Votre compte de jeu associé est le: #{AccountProfile.find_by_msisdn(@msisdn[-8,8]).paymoney_account_number rescue nil}
Veuillez entrer un autre numéro de compte de jeu si vous souhaitez le changer.
0- Retour
00- Accueil]
    @session_identifier = '43'
  end

  def set_default_paymoney_account
    case @ussd_string
      when '0'
        back_to_home
      when '00'
        back_to_home
      else
        @check_pw_account_url = Parameter.first.paymoney_url + "/PAYMONEY_WALLET/rest/check2_compte/#{@ussd_string}"
        @check_pw_account_response = Typhoeus.get(@check_pw_account_url, connecttimeout: 30)

        if !@check_pw_account_response.body.blank? && @check_pw_account_response.body != 'null'
          @pw_account_number = @ussd_string
          @pw_account_token = @check_pw_account_response.body
          # On associe le compte de jeu du client à son numéro
          AccountProfile.find_by_msisdn(@msisdn[-8,8]).update_attributes(paymoney_account_number: @pw_account_number)
          @rendered_text = %Q[Votre compte de jeu associé est le: #{@ussd_string}
Veuillez entrer un autre numéro de compte de jeu si vous souhaitez le changer.
0- Retour
00- Accueil]
          @session_identifier = '43'
        else
          @rendered_text = %Q[Le numéro de compte saisi n'est pas valide
Votre compte de jeu associé est le: #{AccountProfile.find_by_msisdn(@msisdn[-8,8]).paymoney_account_number rescue nil}
Veuillez entrer un autre numéro de compte de jeu si vous souhaitez le changer.
0- Retour
00- Accueil]
          @session_identifier = '43'
        end
      end
  end

  def get_paymoney_other_account_number
    case @ussd_string
      when '0'
        back_to_get_paymoney_sold
      when '00'
        back_to_home
      else
        if @ussd_string.blank?
          @rendered_text = %Q[Veuillez entrer le numéro de compte de jeu dont vous voulez consulter le solde.
0- Retour
00- Accueil]
          @session_identifier = '39'
        else
          @rendered_text = %Q[Veuillez entrer le code secret de jeu du compte dont vous voulez consulter le solde.
0- Retour
00- Accueil]
          @session_identifier = '40'
        end
      end
  end

  def get_paymoney_other_account_password
    case @ussd_string
      when '0'
        back_to_get_paymoney_other_account_number
      when '00'
        back_to_home
      else
        if @ussd_string.blank?
          @rendered_text = %Q[Veuillez entrer le code secret de jeu du compte dont vous voulez consulter le solde.
0- Retour
00- Accueil]
          @session_identifier = '40'
        else
          account_profile = AccountProfile.find_by_msisdn(@msisdn[-8,8])
          #@get_paymoney_sold_url = Parameter.first.paymoney_url + "/PAYMONEY_WALLET/rest/solte_compte/#{@current_ussd_session.other_paymoney_account_number}/#{@ussd_string}"
          @get_paymoney_sold_url = "41.189.40.193:8080/PAYMONEY_WALLET/rest/solte_compte/#{@current_ussd_session.other_paymoney_account_number}/#{@ussd_string}"
          @get_paymoney_sold_response = Typhoeus.get(@get_paymoney_sold_url, connecttimeout: 30)

          balance = JSON.parse(@get_paymoney_sold_response.body)["solde"] rescue nil
          if balance.blank?
            @rendered_text = %Q[Le code secret saisi n'est pas valide.
Veuillez entrer le code secret de jeu du compte dont vous voulez consulter le solde.
0- Retour
00- Accueil]
            @session_identifier = '40'
          else
            @rendered_text = %Q[
Le solde de jeu est de: #{balance rescue 0} FCFA
1- Jeux
2- Mes paris
3- Mon solde
4- Rechargement
5- Votre service SMS
6- Mes OTP
7- Mes comptes
8- Retrait vers MTN MOBILE MONEY]
            @session_identifier = '5'
          end
        end
      end
  end

  def get_paymoney_other_otp_account_number
    case @ussd_string
      when '0'
        back_to_get_paymoney_otp
      when '00'
        back_to_home
      else
        if @ussd_string.blank?
          @rendered_text = %Q[Veuillez entrer le numéro de compte de jeu dont vous souhaitez consulter les OTP.
0- Retour
00- Accueil]
          @session_identifier = '41'
        else
          @rendered_text = %Q[Veuillez entrer le code secret de jeu du compte dont vous voulez consulter les OTP.
0- Retour
00- Accueil]
          @session_identifier = '42'
        end
      end
  end

  def get_paymoney_other_otp_account_password
    case @ussd_string
      when '0'
        back_to_get_paymoney_other_otp_account_number
      when '00'
        back_to_home
      else
        if @ussd_string.blank?
          @rendered_text = %Q[Veuillez entrer le code secret de jeu du compte dont vous voulez consulter les OTP.
0- Retour
00- Accueil]
          @session_identifier = '42'
        else
          account_profile = AccountProfile.find_by_msisdn(@msisdn[-8,8])
          @get_paymoney_otp_url = Parameter.first.paymoney_url + "/PAYMONEY_WALLET/rest/getLastOtp/#{@current_ussd_session.other_otp_paymoney_account_number}/#{@ussd_string}/"
          @get_paymoney_otp_response = Typhoeus.get(@get_paymoney_otp_url, connecttimeout: 30)

          otps = %Q[{"otps":] + (@get_paymoney_otp_response.body rescue nil) + %Q[}]
          otps = JSON.parse(otps)["otps"] rescue nil

          if otps.blank?
            @rendered_text = %Q[Votre liste d'OTP est vide
Veuillez entrer le numéro de compte de jeu dont vous souhaitez consulter les OTP.
0- Retour
00- Accueil]
            @session_identifier = '41'
          else
            otp_string = ""
            otps.each do |otp|
              t = Time.at(((otp["otpDate"].to_s)[0..9]).to_i)
              otp_string << otp["otpPin"] + ' ' + (otp["otpStatus"] == true ? 'Valide' : 'Désactivé') + t.strftime(" %d-%m-%Y ") + t.strftime("%Hh %Mmn") + %Q[
]
            end
            @rendered_text = %Q[Veuillez entrer le numéro de compte de jeu dont vous souhaitez consulter les OTP.
#{otp_string}
0- Retour
00- Accueil]
            @session_identifier = '41'
          end
        end
      end
  end

  def get_paymoney_sold
    case @ussd_string
      when '0'
        @rendered_text = %Q[1- Jeux
2- Mes paris
3- Mon solde
4- Rechargement
5- Votre service SMS
6- Mes OTP
7- Mes comptes
8- Retrait vers MTN MOBILE MONEY]
        @session_identifier = '5'
      when '00'
        back_to_home
      else
        if @ussd_string.blank?
          @rendered_text = %Q[Veuillez entrer votre code secret de jeu pour consulter votre solde.
1- Solde autre compte
0- Retour
00- Accueil]
          @session_identifier = '8'
        else
          if @ussd_string == '1'
            @rendered_text = %Q[Veuillez entrer le numéro de compte de jeu dont vous voulez consulter le solde.
0- Retour
00- Accueil]
            @session_identifier = '39'
          else
            account_profile = AccountProfile.find_by_msisdn(@msisdn[-8,8])
            #@get_paymoney_sold_url = Parameter.first.paymoney_url + "/PAYMONEY_WALLET/rest/solte_compte/#{account_profile.paymoney_account_number}/#{@ussd_string}"
            @get_paymoney_sold_url = "41.189.40.193:8080/PAYMONEY_WALLET/rest/solte_compte/#{account_profile.paymoney_account_number}/#{@ussd_string}"
            @get_paymoney_sold_response = Typhoeus.get(@get_paymoney_sold_url, connecttimeout: 30)

            balance = JSON.parse(@get_paymoney_sold_response.body)["solde"] rescue nil
            if balance.blank?
              @rendered_text = %Q[Le code secret saisi n'est pas valide.
Veuillez entrer votre code secret de jeu pour consulter votre solde.
1- Solde autre compte
0- Retour
00- Accueil]
              @session_identifier = '8'
            else
              @rendered_text = %Q[
Votre solde de jeu est de: #{balance rescue 0} FCFA
1- Jeux
2- Mes paris
3- Mon solde
4- Rechargement
5- Votre service SMS
6- Mes OTP
7- Mes comptes
8- Retrait vers MTN MOBILE MONEY]
              @session_identifier = '5'
            end
          end
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
=begin
      if @current_ussd_session.session_identifier != '-10'
        @rendered_text = %Q[BIENVENUE DANS LE MENU LONACI:
En continuant le processus, vous certifiez avoir +18
1- Continuez
2- Voir termes et conditions
3- Quitter]
        @session_identifier = '-10'
      else
=end
        @rendered_text = %Q[Pour accéder à ce service, créez votre compte PARIONSDIRECT en entrant un mot de passe de 4 caractères.]
        @session_identifier = '1'
      #end
    else
      # Le client a un compte parionsdirect et doit s'authentifier
      @rendered_text = %Q[Veuillez entrer votre mot de passe parionsdirect.]
      @session_identifier = '2'
    end
  end

  def check_parionsdirect_password
    if @ussd_string.blank?
      # Le client n'a pas de compte parionsdirect et entrer un code secret pour en créer un
      @rendered_text = %Q[Veuillez entrer votre mot de passe de compte de jeu.]
      @session_identifier = '2'
    else
      password = Digest::SHA2.hexdigest(@current_ussd_session.parionsdirect_salt + @ussd_string)
      if password == @current_ussd_session.parionsdirect_password
        existing_paymoney_account = AccountProfile.find_by_msisdn(@msisdn[-8,8]).paymoney_account_number rescue nil
        # On vérifie que le client n'a pas déjà de compte de jeu associé à son numéro
        if existing_paymoney_account.blank?
          @rendered_text = %Q[Avez vous un compte de jeu?
1- Oui
2- Non]
          @session_identifier = '4-'
=begin
          @rendered_text = %Q[Veuillez saisir votre numéro de compte de jeu.]
          @session_identifier = '4'
=end
        else
          @rendered_text = %Q[BIENVENUE DANS LE MENU LONACI:
1- Recharger compte de jeu
2- Jouer
3- Termes et conditions]
          @session_identifier = '5--'
        end
      else
        @rendered_text = %Q[Le code secret saisi n'est pas valide.
Veuillez entrer votre mot de passe parionsdirect.
          ]
        @session_identifier = '2'
      end
    end
  end

  def check_paymoney_account_number
    if @ussd_string.blank?
      # Le client saisit son numéro de compte de jeu pour le faire valider
      @rendered_text = %Q[Veuillez saisir votre numéro de compte de jeu.]
      @session_identifier = '4'
    else
      @check_pw_account_url = Parameter.first.paymoney_url + "/PAYMONEY_WALLET/rest/check2_compte/#{@ussd_string}"
      @check_pw_account_response = Typhoeus.get(@check_pw_account_url, connecttimeout: 30)

      if !@check_pw_account_response.body.blank? && @check_pw_account_response.body != 'null'
        @pw_account_number = @ussd_string
        @pw_account_token = @check_pw_account_response.body
        # On associe le compte de jeu du client à son numéro
        AccountProfile.find_by_msisdn(@msisdn[-8,8]).update_attributes(paymoney_account_number: @pw_account_number) rescue AccountProfile.create(msisdn: @msisdn[-8,8], paymoney_account_number: @pw_account_number) rescue nil
        @rendered_text = %Q[BIENVENUE DANS LE MENU LONACI:
1- Recharger compte de jeu
2- Jouer
3- Termes et conditions]
        @session_identifier = '5--'
      else
        @rendered_text = %Q[Le compte de jeu fourni n'a pas été trouvé.
Veuillez saisir votre numéro de compte de jeu.]
        @session_identifier = '4'
      end
    end
  end

  # Création d'un nouveau compte parionsdirect par saisie du code secret
  def set_parionsdirect_password
    # L'utilisateur n'a pas saisi de code secret, on le ramène au menu précédent
    if @ussd_string.blank? || @ussd_string.length != 4
      # Le client n'a pas de compte parionsdirect et entrer un code secret pour en créer un
      @rendered_text = %Q[Pour accéder à ce service, créez votre compte PARIONSDIRECT en entrant un mot de passe de 4 caractères.]
      @session_identifier = '1'
    else
      @creation_pd_password = @ussd_string
      # Le client n'a pas de compte parionsdirect et confirmer le code secret pour en créer un
      @rendered_text = %Q[Veuillez confirmer le mot de passe précédemment entré.]
      @session_identifier = '3'
    end
  end

  # Création d'un nouveau compte parionsdirect par confirmation du code secret et création d'un compte de jeu
  def create_parionsdirect_account
    # L'utilisateur n'a pas saisi de confirmation de code secret, on le ramène au menu précédent
    if @ussd_string.blank? || @ussd_string.length != 4
      # Le client n'a pas de compte parionsdirect et confirmer le code secret pour en créer un
      @rendered_text = %Q[Veuillez confirmer le mot de passe précédemment entré.]
      @session_identifier = '3'
    else
      @creation_pd_password_confirmation = @ussd_string
      # Les mots de passe saisis ne sont pas identiques
      if @current_ussd_session.creation_pd_password != @creation_pd_password_confirmation
        # Le client n'a pas de compte parionsdirect et confirmer le code secret pour en créer un
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
Veuillez confirmer le mot de passe précédemment entré.]
          @session_identifier = '3'
        else
          @pd_account_created = true
          @rendered_text = %Q[Votre compte PARIONSDIRECT a été créé avec succès. Pour jouer, il vous faut un compte de jeu. Avez vous un compte de jeu?
1- Oui
2- Non]
          @session_identifier = '4-'
        end
      end
    end
  end

  def create_paymoney_account
    if ['1', '2'].include?(@ussd_string)
      if @ussd_string == '2'
        # Création du compte de jeu du client
        #@creation_pw_request = Parameter.first.paymoney_url + "/PAYMONEY_WALLET/rest/ussd_create_compte/#{@msisdn[-8,8]}"
        @creation_pw_request = "41.189.40.193:8080/PAYMONEY_WALLET/rest/ussd_create_compte/#{@msisdn[-8,8]}"
        @creation_pw_response = Typhoeus.get(@creation_pw_request, connecttimeout: 30)
        paymoney_account = JSON.parse(@creation_pw_response.body) rescue nil
        # Le compte de jeu a été créé
        if (paymoney_account["errors"] rescue nil).blank?
          AccountProfile.create(msisdn: @msisdn[-8,8], paymoney_account_number: paymoney_account["compte"])
          @pw_account_created = true
          @rendered_text = %Q[Vous allez recevoir un SMS avec les détails de votre porte monnaie de jeu.]
          @session_identifier = '4'
        else
          @pw_account_created = false
          @rendered_text = %Q[Veuillez réessayer. Pour jouer, il vous faut un compte de jeu. Avez vous un compte de jeu?
1- Oui
2- Non]
          @session_identifier = '4-'
        end
      else
        # Le client saisit son numéro de compte de jeu pour le faire valider
        @rendered_text = %Q[Veuillez saisir votre numéro de compte de jeu.]
        @session_identifier = '4'
      end
    else
      @rendered_text = %Q[Votre compte PARIONSDIRECT a été créé avec succès. Pour jouer, il vous faut un compte de jeu. Avez vous un compte de jeu?
1- Oui
2- Non]
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
            <loc:msgType>#{@reload == true ? '2' : msg_type}</loc:msgType>
            <loc:senderCB>#{sender_cb}</loc:senderCB>
            <loc:receiveCB>#{sender_cb}</loc:receiveCB>
            <loc:ussdOpType>#{@reload == true ? '3' : '1'}</loc:ussdOpType>
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
        @selector2 = 35 + DateTime.parse("01/01/#{Date.today.year} 19:00:00").upto(DateTime.now).count(&:monday?)
      when 'emergence'
        @selector2 = 36 + DateTime.parse("01/01/#{Date.today.year} 19:00:00").upto(DateTime.now).count(&:tuesday?)
      when 'fortune'
        @selector2 = 44 + DateTime.parse("01/01/#{Date.today.year} 19:00:00").upto(DateTime.now).count(&:wednesday?)
      when 'privilege'
        @selector2 = 36 + DateTime.parse("01/01/#{Date.today.year} 19:00:00").upto(DateTime.now).count(&:thursday?)
      when 'solution'
        @selector2 = 36 + DateTime.parse("01/01/#{Date.today.year} 19:00:00").upto(DateTime.now).count(&:friday?)
      when 'diamant'
        @selector2 = 45 + DateTime.parse("01/01/#{Date.today.year} 19:00:00").upto(DateTime.now).count(&:saturday?)
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
    @get_plr_race_list_request = Parameter.first.parionsdirect_url + "/ussd_pmu/get_plr_race_list"
    @get_plr_race_list_response = RestClient.get(@get_plr_race_list_request) rescue nil
    @reunions = []
    @reunion_string = ""
    counter = 0

    races = JSON.parse(@get_plr_race_list_response) rescue nil
    races = races["plr_race_list"] rescue nil

    unless races.blank?
      races.each do |race|
        if !@reunions.include?(race["reunion"])
          @reunions << race["reunion"]
          @reunion_string << race["reunion"] << "
"
        end
      end
    end

    @rendered_text = %Q[PMU PLR
Veuillez entrer le numéro de réunion
#{@reunion_string}
0- Retour
00- Accueil]
    @session_identifier = '20'
  end

  def plr_get_race
    #@get_plr_race_list_request = Parameter.first.parionsdirect_url + "/ussd_pmu/get_plr_race_list"
    #@get_plr_race_list_response = RestClient.get(@get_plr_race_list_request) rescue nil
    @reunions = []
    @reunion_string = ""
    @race_string = ""
    counter = 0

    races = JSON.parse(@current_ussd_session.get_plr_race_list_response) rescue nil
    races = races["plr_race_list"] rescue nil

    unless races.blank?
      races.each do |race|
        if !@reunions.include?(race["reunion"])
          @reunions << race["reunion"]
          @reunion_string << race["reunion"] << "
"
        end
        if race["reunion"] == "R" + @ussd_string
          @race_string << "#{race["course"]}" << " #{race["depart"]}" << "
"
        end
      end
    end

    case @ussd_string
      when '0'
        back_list_games_menu
      when '00'
        back_list_main_menu
      else
        if @ussd_string.blank?
          @rendered_text = %Q[PMU PLR
Veuillez entrer le numéro de réunion
#{@reunion_string}
0- Retour
00- Accueil]
          @session_identifier = '20'
        else
          plr_get_reunions_list
          @get_plr_race_list_request = @get_plr_race_list_request
          @get_plr_race_list_response = @get_plr_race_list_response

          if !@reunions.include?('R' + @ussd_string)
            @rendered_text = %Q[PMU PLR
Veuillez entrer un numéro de réunion valide
#{@reunion_string}
0- Retour
00- Accueil]
            @session_identifier = '20'
          else
            @rendered_text = %Q[PMU PLR
Veuillez entrer le numéro de course
Réunion: R#{@ussd_string}
#{@race_string}
0- Retour
00- Accueil]
            @session_identifier = '21'
          end
        end
      end
  end

  def plr_game_selection
    @reunions = []
    @reunion_string = ""
    @race_string = ""
    counter = 0

    races = JSON.parse(@current_ussd_session.get_plr_race_list_response) rescue nil
    races = races["plr_race_list"] rescue nil

    unless races.blank?
      races.each do |race|
        if !@reunions.include?(race["reunion"])
          @reunions << race["reunion"]
          @reunion_string << race["reunion"] << "
"
        end

        if race["reunion"] == "R" + @current_ussd_session.plr_reunion_number
          @race_string << "#{race["course"]}" << " #{race["depart"]}" << "
"
        end
      end
    end

    case @ussd_string
      when '0'
        back_to_plr_get_reunion
      when '00'
        back_list_main_menu
      else
        if @ussd_string.blank?
          @rendered_text = %Q[PMU PLR
Veuillez entrer un numéro de course valide
Réunion: R#{@current_ussd_session.plr_reunion_number}
#{@race_string}
0- Retour
00- Accueil]
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
Veuillez entrer un numéro de course valide
Réunion: R#{@current_ussd_session.plr_reunion_number}
0- Retour
00- Accueil]
          @session_identifier = '21'
          else
            @rendered_text = %Q[PMU PLR
Vous avez sélectionné la course: Réunion: R#{@current_ussd_session.plr_reunion_number} - Course: C#{@ussd_string}
1- Jouer
2- Détail des courses
0- Retour
00- Accueil]
            @session_identifier = '22'
          end
        end
      end
  end

  def set_session_identifier_depending_on_plr_game_selection
    @status = false
    if !['1', '2', '0', '00'].include?(@ussd_string)
      @rendered_text = %Q[PMU PLR
Vous avez sélectionné la course: Réunion: R#{@current_ussd_session.plr_reunion_number} - Course: C#{@ussd_string}
1- Jouer
2- Détail des courses
0- Retour
00- Accueil]
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
Détails: #{race["details"]}
0- Retour
00- Accueil]
    end
    @session_identifier = '22-'
  end

  def display_plr_bet_type
    @rendered_text = %Q[Réunion: R#{@current_ussd_session.plr_reunion_number} - Course: C#{@current_ussd_session.plr_race_number}
1- Trio
2- Jumelé gagnant
3- Jumelé placé
4- Simple gagnant
5- Simple placé
0- Retour
00- Accueil]
    @session_identifier = '23'
  end

  def set_session_identifier_depending_on_plr_bet_type_selected
    @status = false
    if ['1', '2', '3', '4', '5', '0', '00'].include?(@ussd_string)
      @status = true
    else
      @rendered_text = %Q[Réunion: R#{@current_ussd_session.plr_reunion_number} - Course: C#{@current_ussd_session.plr_race_number}
1- Trio
2- Jumelé gagnant
3- Jumelé placé
4- Simple gagnant
5- Simple placé
0- Retour
00- Accueil]
      @session_identifier = '23'
    end
  end

  def set_session_identifier_depending_on_plr_formula_selected
    @status = false
    if ['1', '2', '3', '0', '00'].include?(@ussd_string)
      @status = true
    else
      @rendered_text = %Q[Réunion: R#{@current_ussd_session.plr_reunion_number} - Course: C#{@current_ussd_session.plr_race_number}
1- Long champ
2- Champ réduit
3- Champ total
0- Retour
00- Accueil]
      @session_identifier = '23'
    end
  end

  def plr_display_plr_formula
    @rendered_text = %Q[Réunion: R#{@current_ussd_session.plr_reunion_number} - Course: C#{@current_ussd_session.plr_race_number}
1- Long champ
2- Champ réduit
3- Champ total
0- Retour
00- Accueil]
    @session_identifier = '24'
  end

  def plr_display_plr_selection
    @rendered_text = %Q[Réunion: R#{@current_ussd_session.plr_reunion_number} - Course: C#{@current_ussd_session.plr_race_number}
Saisissez les numéros de vos chevaux en les séparant par un espace
0- Retour
00- Accueil]
    @session_identifier = '26'
  end

  def plr_display_plr_base
    @rendered_text = %Q[Réunion: R#{@current_ussd_session.plr_reunion_number} - Course: C#{@current_ussd_session.plr_race_number}
Saisissez la base
0- Retour
00- Accueil]
    @session_identifier = '25'
  end

  def plr_select_number_of_times
    @ussd_string = @ussd_string
    case @ussd_string
      when '0'
        if @current_ussd_session.plr_formula_shortcut == 'champ_reduit'
          back_to_plr_select_base
        else
          back_to_plr_select_formula
        end
      when '00'
        back_list_main_menu
      else
        if plr_valid_horses_numbers
          if plr_right_selection
            if plr_numbers_in_selection_not_in_base
              @rendered_text = %Q[Réunion: R#{@current_ussd_session.plr_reunion_number} - Course: C#{@current_ussd_session.plr_race_number}
Veuillez saisir le nombre de fois que vous souhaitez miser
0- Retour
00- Accueil]
              @session_identifier = '27'
            else
              @rendered_text = %Q[#{@error_message}
Réunion: R#{@current_ussd_session.plr_reunion_number} - Course: C#{@current_ussd_session.plr_race_number}
Saisissez les numéros de vos chevaux en les séparant par un espace
0- Retour
00- Accueil]
              @session_identifier = '26'
            end
          else
            @rendered_text = %Q[#{@error_message}
Réunion: R#{@current_ussd_session.plr_reunion_number} - Course: C#{@current_ussd_session.plr_race_number}
Saisissez les numéros de vos chevaux en les séparant par un espace
0- Retour
00- Accueil]
            @session_identifier = '26'
          end
        else
          @rendered_text = %Q[#{@error_message}
Réunion: R#{@current_ussd_session.plr_reunion_number} - Course: C#{@current_ussd_session.plr_race_number}
Saisissez les numéros de vos chevaux en les séparant par un espace
0- Retour
00- Accueil]
          @session_identifier = '26'
        end
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
    @current_ussd_session = @current_ussd_session
    case @ussd_string
      when '0'
        back_to_plr_select_formula
      when '00'
        back_list_main_menu
      else
        if @current_ussd_session.plr_formula_shortcut == 'champ_reduit'
          @rendered_text = %Q[Réunion: R#{@current_ussd_session.plr_reunion_number} - Course: C#{@current_ussd_session.plr_race_number}
Saisissez les numéros de vos chevaux en les séparant par un espace
0- Retour
00- Accueil]
          @session_identifier = '26'
        else
          @rendered_text = %Q[Réunion: R#{@current_ussd_session.plr_reunion_number} - Course: C#{@current_ussd_session.plr_race_number}
Veuillez saisir le nombre de fois que vous souhaitez miser
0- Retour
00- Accueil]
          @session_identifier = '27'
        end
      end
  end

  def plr_evaluate_bet
    @error_message = ''
    @current_ussd_session = @current_ussd_session
    case @ussd_string
      when '0'
        back_to_plr_select_selection
      when '00'
        back_list_main_menu
      else
        if @ussd_string.blank? || not_a_number?(@ussd_string)
          @rendered_text = %Q[Réunion: R#{@current_ussd_session.plr_reunion_number} - Course: C#{@current_ussd_session.plr_race_number}
Veuillez saisir le nombre de fois que vous souhaitez miser
0- Retour
00- Accueil]
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
Veuillez saisir le nombre de fois que vous souhaitez miser
0- Retour
00- Accueil]
            @session_identifier = '27'
          else
            if json_object["error"].blank?
              @rendered_text = %Q[Vous vous apprêtez à prendre un pari PMU PLR
R#{@current_ussd_session.plr_reunion_number}C#{@current_ussd_session.plr_race_number}
#{@current_ussd_session.plr_bet_type_label} > #{@current_ussd_session.plr_formula_label}
#{@current_ussd_session.plr_base.blank? ? '' : "Base: " + @current_ussd_session.plr_base}
#{@current_ussd_session.plr_selection.blank? ? '' : "Sélection: " + @current_ussd_session.plr_selection}
Votre pari est estimé à #{json_object["bet"]["bet_cost_amount"]} FCFA.
Confirmez en saisissant votre code secret
0- Retour
00- Accueil]
              @bet_cost_amount = json_object["bet"]["bet_cost_amount"]
              @session_identifier = '28'
            else
              @rendered_text = %Q[Le pari n'a pas pu être évalué
Réunion: R#{@current_ussd_session.plr_reunion_number} - Course: C#{@current_ussd_session.plr_race_number}
Veuillez saisir le nombre de fois que vous souhaitez miser
0- Retour
00- Accueil]
              @session_identifier = '27'
            end
          end
        end
      end
  end

  def plr_place_bet
    @current_ussd_session = @current_ussd_session
    case @ussd_string
      when '0'
        back_to_plr_select_stake
      when '00'
        back_list_main_menu
      else
        if @ussd_string.blank?
          @rendered_text = %Q[Vous vous apprêtez à prendre un pari PMU PLR
R#{@current_ussd_session.plr_reunion_number}C#{@current_ussd_session.plr_race_number}
#{@current_ussd_session.plr_bet_type_label} > #{@current_ussd_session.plr_formula_label}
#{@current_ussd_session.plr_base.blank? ? '' : "Base: " + @current_ussd_session.plr_base}
#{@current_ussd_session.plr_selection.blank? ? '' : "Sélection: " + @current_ussd_session.plr_selection}
Votre pari est estimé à #{@current_ussd_session.bet_cost_amount} FCFA.
Confirmez en saisissant votre code secret
0- Retour
00- Accueil]
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
Confirmez en saisissant votre code secret
0- Retour
00- Accueil]
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
Confirmez en saisissant votre code secret
0- Retour
00- Accueil]
              @session_identifier = '28'
            else
              if json_object["error"].blank?
                status = true
                @reunions = []
                @reunion_string = ""
                races = JSON.parse(@current_ussd_session.get_plr_race_list_response) rescue nil
                races = races["plr_race_list"] rescue nil

                unless races.blank?
                  races.each do |race|
                    if !@reunions.include?(race["reunion"])
                      @reunions << race["reunion"]
                      @reunion_string << race["reunion"] << "
"
                    end
                  end
                end
                @rendered_text = %Q[FELICITATIONS, votre pari a bien été enregistré.
N° de ticket: #{json_object["bet"]["ticket_number"]}
REF: #{json_object["bet"]["ref_number"]}
PMU, PARIE  POUR GAGNER!
Veuillez entrer le numéro de réunion
#{@reunion_string}
0- Retour
00- Accueil]
                @session_identifier = '20'
              else
                @rendered_text = %Q[Le pari n'a pas pu être placé.
R#{@current_ussd_session.plr_reunion_number}C#{@current_ussd_session.plr_race_number}
#{@current_ussd_session.plr_bet_type_label} > #{@current_ussd_session.plr_formula_label}
#{@current_ussd_session.plr_base.blank? ? '' : "Base: " + @current_ussd_session.plr_base}
#{@current_ussd_session.plr_selection.blank? ? '' : "Sélection: " + @current_ussd_session.plr_selection}
Votre pari est estimé à #{@current_ussd_session.bet_cost_amount} FCFA.
Confirmez en saisissant votre code secret
0- Retour
00- Accueil]
                @session_identifier = '28'
              end
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
          @bet_modifier = '2'
        when 'champ_total'
          @bet_code = '109'
          @bet_modifier = '1'
        end
    end
    if @current_ussd_session.plr_bet_type_shortcut == 'jumele_place'
      case @current_ussd_session.plr_formula_shortcut
        when 'long_champs'
          @bet_code = '108'
          @bet_modifier = '0'
        when 'champ_reduit'
          @bet_code = '112'
          @bet_modifier = '2'
        when 'champ_total'
          @bet_code = '110'
          @bet_modifier = '1'
        end
    end
    if @current_ussd_session.plr_bet_type_shortcut == 'trio'
      if @current_ussd_session.plr_formula_shortcut == 'long_champs'
        @bet_code = '102'
        @bet_modifier = '0'
      end
      if @current_ussd_session.plr_formula_shortcut == 'champ_reduit'
        if @current_ussd_session.plr_base.split().length == 1
          @bet_code = '104'
          @bet_modifier = '2'
        else
          @bet_code = '106'
          @bet_modifier = '2'
        end
      end
      if @current_ussd_session.plr_formula_shortcut == 'champ_total'
        if @current_ussd_session.plr_base.split().length == 1
          @bet_code = '103'
          @bet_modifier = '1'
        else
          @bet_code = '105'
          @bet_modifier = '1'
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

    if @alr_race_ids.length == 0 || @race_data.blank? #@alr_program_status != 'ON' ||
      @rendered_text = %Q[PMU - ALR - Il n'y a aucun programme disponible
1- Loto Bonheur
2- PMU ALR
3- PMU PLR
4- SPORTCASH
0- Retour
00- Accueil]
      @session_identifier = '11'
    else
      races = ""
      @alr_race_ids.split('-').each do |race_id|
         races << race_id[-1,1] + " - Nationale" + race_id[-1,1] + "
"
      end
      @rendered_text = %Q[PMU - ALR
#{races}
0- Retour
00- Accueil]
      @session_identifier = '30'
    end
  end

  def alr_display_bet_type
    status = false
     case @ussd_string
      when '0'
        back_list_games_menu
      when '00'
        back_list_main_menu
      else
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
                  @race_details << "#{custom_index+=1}- Tiercé 2
"
                  @alr_bet_type_menu << "#{custom_index}-tierce2 "
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
#{@race_details}
0- Retour
00- Accueil]
          @session_identifier = '31'
        else
          races = ""
          @current_ussd_session.alr_race_ids.split('-').each do |race_id|
             races << race_id[-1,1] + " - Nationale" + race_id[-1,1] + "
"
          end
          @rendered_text = %Q[PMU - ALR
#{races}
0- Retour
00- Accueil]
          @session_identifier = '30'
        end
      end
  end

  def alr_display_formula
    case @ussd_string
      when '0'
        back_alr_list_races
      when '00'
        back_list_main_menu
      else
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
              @race_details << "#{custom_index+=1}- Tiercé 2
"
              @alr_bet_type_menu << "#{custom_index}-tierce2 "
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
            when 'tierce2'
              @bet_type_label = 'Tiercé 2'
              @alr_bet_id = '14'
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
4- Multi 4/7
0- Retour
00- Accueil]
            @session_identifier = '33'
          else
            @rendered_text = %Q[PMU - ALR
#{@current_ussd_session.national_label} > #{@bet_type_label}
#{@race_header}
1- Long champ
2- Champ réduit
3- Champ total
0- Retour
00- Accueil]
            @session_identifier = '32'
          end
        else

          @rendered_text = %Q[PMU - ALR
#{@current_ussd_session.national_label}
#{@race_header}
#{@race_details}
0- Retour
00- Accueil]
          @session_identifier = '31'
        end
      end
  end

  def set_session_identifier_depending_on_alr_bet_type_selected
    @status = false
    if ['1', '2', '3', '0', '00'].include?(@ussd_string)
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
3- Champ total
0- Retour
00- Accueil]
      @session_identifier = '32'
    end
  end

  def set_session_identifier_depending_on_alr_multi_selected
    @status = false
    if ['1', '2', '3', '4', '0', '00'].include?(@ussd_string)
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
4- Multi 4/7
0- Retour
00- Accueil]
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
Saisissez les numéros de vos chevaux séparés par un espace
0- Retour
00- Accueil]
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
Saisissez le numero de votre cheval de BASE et ulitiser X pour definir l'emplacement de votre selection
0- Retour
00- Accueil]
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

    case @ussd_string
      when '0'
        back_to_alr_selection
      when '00'
        back_list_main_menu
      else
        if ['1', '2'].include?(@ussd_string)
          @ussd_string == '1' ? @full_formula = true : @full_formula = false
          @rendered_text = %Q[PMU - ALR
#{@current_ussd_session.national_label} > #{@current_ussd_session.alr_bet_type_label}
#{@race_header}
Saisissez le nombre de fois
0- Retour
00- Accueil]
          @session_identifier = '37'
        else
          @rendered_text = %Q[PMU - ALR
#{@current_ussd_session.national_label} > #{@current_ussd_session.alr_bet_type_label}
#{@race_header}
Voulez-vous jouer en formule complète?
1- Oui
2- Non
0- Retour
00- Accueil]
          @session_identifier = '36'
        end
      end
  end

  def validate_alr_base
    case @ussd_string
      when '0'
        back_to_alr_select_formula
      when '00'
        back_list_main_menu
      else
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
Saisissez les numéros de vos chevaux séparés par un espace
0- Retour
00- Accueil]
            @session_identifier = '35'
          else
            if @current_ussd_session.alr_formula_label == 'Champ total'
              @rendered_text = %Q[PMU - ALR
#{@current_ussd_session.national_label} > #{@current_ussd_session.alr_bet_type_label}
#{@race_header}
Voulez-vous jouer en formule complète?
1- Oui
2- Non
0- Retour
00- Accueil]
              @session_identifier = '36'
            else
              @rendered_text = %Q[PMU - ALR
#{@current_ussd_session.national_label} > #{@current_ussd_session.alr_bet_type_label}
#{@race_header}
Saisissez le nombre de fois
0- Retour
00- Accueil]
              @session_identifier = '37'
            end
          end
        else
          @rendered_text = %Q[PMU - ALR
#{@current_ussd_session.national_label} > #{@current_ussd_session.alr_bet_type_label}
#{@race_header}
Saisissez le numero de votre cheval de BASE et utiliser X pour definir l'emplacement de votre selection
0- Retour
00- Accueil]
          @session_identifier = '34'
        end
      end
  end

  def validate_alr_horses
    @ussd_string = @ussd_string
    @current_ussd_session = @current_ussd_session
    case @ussd_string
      when '0'
        if ['champ_reduit', 'champ_total'].include?(@current_ussd_session.alr_formula_shortcut)
          back_to_alr_select_base
        else
          if [' 4/4', ' 4/5', ' 4/6', ' 4/7'].include?(@current_ussd_session.alr_formula_shortcut)
            back_to_alr_multi_selection
          else
            back_to_alr_select_formula
          end
        end
      when '00'
        back_list_main_menu
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
    "
          end
        end

        if alr_valid_horses_numbers
          if alr_valid_multi_number_of_horses && alr_valid_selection_numbers
            if ['Tiercé', 'Tiercé 2', 'Quarté', 'Quinté', 'Quinté +'].include?(@current_ussd_session.alr_bet_type_label)
              @rendered_text = %Q[PMU - ALR
#{@current_ussd_session.national_label} > #{@current_ussd_session.alr_bet_type_label}
#{@race_header}
Voulez-vous jouer en formule complète?
1- Oui
2- Non
0- Retour
00- Accueil]
              @session_identifier = '36'
            else
              @rendered_text = %Q[PMU - ALR
#{@current_ussd_session.national_label} > #{@current_ussd_session.alr_bet_type_label}
#{@race_header}
Saisissez le nombre de fois
0- Retour
00- Accueil]
              @session_identifier = '37'
            end
          else
            @rendered_text = %Q[#{@error_message}
PMU - ALR
#{@current_ussd_session.national_label} > #{@current_ussd_session.alr_bet_type_label}
#{@race_header}
Saisissez les numéros de vos chevaux séparés par un espace
0- Retour
00- Accueil]
            @session_identifier = '35'
          end
        else
          @rendered_text = %Q[#{@error_message}
PMU - ALR
#{@current_ussd_session.national_label} > #{@current_ussd_session.alr_bet_type_label}
#{@race_header}
Saisissez les numéros de vos chevaux séparés par un espace
0- Retour
00- Accueil]
          @session_identifier = '35'
        end
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
    case @ussd_string
      when '0'
        if ['Tiercé', 'Tiercé 2', 'Quarté', 'Quinté', 'Quinté +'].include?(@current_ussd_session.alr_bet_type_label)
          back_to_alr_full_formula
        else
          back_to_alr_selection
        end
      when '00'
        back_list_main_menu
      else
        if @ussd_string.blank? || not_a_number?(@ussd_string)
          @rendered_text = %Q[PMU - ALR
#{@current_ussd_session.national_label} > #{@current_ussd_session.alr_bet_type_label}
#{@race_header}
Saisissez le nombre de fois
0- Retour
00- Accueil]
          @session_identifier = '37'
        else
          @program_id = @current_ussd_session.alr_program_id
          @race_id = @current_ussd_session.alr_race_ids.split('-')[@current_ussd_session.national_shortcut.to_i - 1] rescue nil

          @alr_evaluate_bet_request = Parameter.first.gateway_url + "/cm3/api/0cad36b144/game/evaluate/#{@current_ussd_session.alr_program_id}/#{@race_id}"
          comma = @current_ussd_session.alr_selection.blank? ? '' : ','
          items = @current_ussd_session.alr_base.to_s.split().join(',') + (@current_ussd_session.alr_base.blank? ? '' : comma) + @current_ussd_session.alr_selection.to_s.split().join(',')
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
Saisissez le nombre de fois
0- Retour
00- Accueil]
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
Veuillez entrer votre code secret de jeu pour valider le pari.
0- Retour
00- Accueil]
              @session_identifier = '38'
            else
              @rendered_text = %Q[PMU - ALR
Le pari n'a pas pu être évalué
#{@current_ussd_session.national_label} > #{@current_ussd_session.alr_bet_type_label}
#{@race_header}
Saisissez le nombre de fois
0- Retour
00- Accueil]
              @session_identifier = '37'
            end
          end
        end
      end
  end

  def alr_place_bet
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

    case @ussd_string
      when '0'
        back_to_alr_stake
      when '00'
        back_list_main_menu
      else
        if @ussd_string.length != 4 || not_a_number?(@ussd_string)
          @rendered_text = %Q[Vous vous apprêtez à prendre un pari PMU ALR
#{@current_ussd_session.national_label} > #{@current_ussd_session.alr_bet_type_label}
#{@race_header}
#{@current_ussd_session.alr_base.blank? ? '' : "Base: " + @current_ussd_session.alr_base}
#{@current_ussd_session.alr_selection.blank? ? '' : "Sélection: " + @current_ussd_session.alr_selection}
Votre pari est estimé à #{@current_ussd_session.alr_amount} FCFA
Veuillez entrer votre code secret de jeu pour valider le pari.
0- Retour
00- Accueil]
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
Veuillez entrer votre code secret de jeu pour valider le pari.
0- Retour
00- Accueil]
            @session_identifier = '38'
          else
            @program_id = @current_ussd_session.alr_program_id
            @race_id = @current_ussd_session.alr_race_ids.split('-')[@current_ussd_session.national_shortcut.to_i - 1] rescue nil
            @alr_place_bet_request = Parameter.first.gateway_url + "/cm3/api/98d24611fd/ticket/sell/#{@get_gamer_id_response.body}/#{@account_profile.paymoney_account_number}/#{@ussd_string}/#{@current_ussd_session.alr_program_date}/#{@current_ussd_session.alr_program_date}"
            comma = @current_ussd_session.alr_selection.blank? ? '' : ','
            items = @current_ussd_session.alr_base.to_s.split().join(',') + (@current_ussd_session.alr_base.blank? ? '' : comma) + @current_ussd_session.alr_selection.to_s.split().join(',')
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
              @rendered_text = %Q[Le pari n'a pas pu être pris
Vous vous apprêtez à prendre un pari PMU ALR
#{@current_ussd_session.national_label} > #{@current_ussd_session.alr_bet_type_label}
#{@race_header}
#{@current_ussd_session.alr_base.blank? ? '' : "Base: " + @current_ussd_session.alr_base}
#{@current_ussd_session.alr_selection.blank? ? '' : "Sélection: " + @current_ussd_session.alr_selection}
Votre pari est estimé à #{@current_ussd_session.alr_amount} FCFA
Veuillez entrer votre code secret de jeu pour valider le pari.
0- Retour
00- Accueil]
              @session_identifier = '38'
            else
              if json_object["error"].blank?
                races = ""
                @current_ussd_session.alr_race_ids.split('-').each do |race_id|
                   races << race_id[-1,1] + " - Nationale" + race_id[-1,1] + "
"
                end
                @rendered_text = %Q[FELICITATIONS, votre pari a bien été enregistré.
Numéro de ticket: #{json_object["bet"]["serial_number"]}
PMU, PARIE  POUR GAGNER!
#{races}
0- Retour
00- Accueil]
                @session_identifier = '30'
              else
                @rendered_text = %Q[Le pari n'a pas pu être pris
Vous vous apprêtez à prendre un pari PMU ALR
#{@current_ussd_session.national_label} > #{@current_ussd_session.alr_bet_type_label}
#{@race_header}
#{@current_ussd_session.alr_base.blank? ? '' : "Base: " + @current_ussd_session.alr_base}
#{@current_ussd_session.alr_selection.blank? ? '' : "Sélection: " + @current_ussd_session.alr_selection}
Votre pari est estimé à #{@current_ussd_session.alr_amount} FCFA
Veuillez entrer votre code secret de jeu pour valider le pari.
0- Retour
00- Accueil]
                @session_identifier = '38'
              end
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
    unless @current_ussd_session.alr_base.blank?
      @current_ussd_session.alr_base.split.each do |base_number|
        if @ussd_string.split.include?(base_number)
          status = false
          @error_message = "Veuillez choisir des numéros différents en base et en sélection"
        end
      end
    end
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
    if @current_ussd_session.alr_bet_type_label == 'Tiercé 2' && @current_ussd_session.alr_formula_label == 'Champ réduit' && @ussd_string.split.length < 2
      @error_message = "Vous devez choisir au moins 2 numéros"
      status = false
    end
    if @current_ussd_session.alr_bet_type_label == 'Tiercé 2' && @ussd_string.split.length < 3
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

    if @current_ussd_session.alr_bet_type_label == 'Couplé gagnant' && @current_ussd_session.alr_formula_label == 'Champ réduit' && (@ussd_string.split.length != 2 || !@ussd_string.downcase.split.include?('x'))
      @error_message = "Vous devez choisir 2 numéros"
      status = false
    end
    if @current_ussd_session.alr_bet_type_label == 'Couplé gagnant' && @current_ussd_session.alr_formula_label == 'Champ total' && (@ussd_string.split.length != 2 || !@ussd_string.downcase.split.include?('x'))
      @error_message = "Vous devez choisir 2 numéros"
      status = false
    end
    if @current_ussd_session.alr_bet_type_label == 'Couplé placé' && @current_ussd_session.alr_formula_label == 'Champ réduit' && (@ussd_string.split.length != 2 || !@ussd_string.downcase.split.include?('x'))
      @error_message = "Vous devez choisir 2 numéros"
      status = false
    end
    if @current_ussd_session.alr_bet_type_label == 'Tiercé' && @current_ussd_session.alr_formula_label == 'Champ réduit' && (@ussd_string.split.length != 3 || !@ussd_string.downcase.split.include?('x'))
      @error_message = "Vous devez choisir 3 numéros"
      status = false
    end
    if @current_ussd_session.alr_bet_type_label == 'Tiercé' && @current_ussd_session.alr_formula_label == 'Champ total' && (@ussd_string.split.length != 3 || !@ussd_string.downcase.split.include?('x'))
      @error_message = "Vous devez choisir 3 numéros"
      status = false
    end
    if @current_ussd_session.alr_bet_type_label == 'Tiercé 2' && @current_ussd_session.alr_formula_label == 'Champ réduit' && (@ussd_string.split.length != 3 || !@ussd_string.downcase.split.include?('x'))
      @error_message = "Vous devez choisir 3 numéros"
      status = false
    end
    if @current_ussd_session.alr_bet_type_label == 'Tiercé 2' && @current_ussd_session.alr_formula_label == 'Champ total' && (@ussd_string.split.length != 3 || !@ussd_string.downcase.split.include?('x'))
      @error_message = "Vous devez choisir 3 numéros"
      status = false
    end
    if @current_ussd_session.alr_bet_type_label == 'Quarté' && @current_ussd_session.alr_formula_label == 'Champ réduit' && (@ussd_string.split.length != 4 || !@ussd_string.downcase.split.include?('x'))
      @error_message = "Vous devez choisir 4 numéros"
      status = false
    end
    if @current_ussd_session.alr_bet_type_label == 'Quarté' && @current_ussd_session.alr_formula_label == 'Champ total' && (@ussd_string.split.length != 4 || !@ussd_string.downcase.split.include?('x'))
      @error_message = "Vous devez choisir 4 numéros"
      status = false
    end
    if (@current_ussd_session.alr_bet_type_label == 'Quinté' || @current_ussd_session.alr_bet_type_label == 'Quinté +') && @current_ussd_session.alr_formula_label == 'Champ réduit' && (@ussd_string.split.length != 5 || !@ussd_string.downcase.split.include?('x'))
      @error_message = "Vous devez choisir 5 numéros"
      status = false
    end
    if (@current_ussd_session.alr_bet_type_label == 'Quinté' || @current_ussd_session.alr_bet_type_label == 'Quinté +') && (@ussd_string.split.length != 5 || !@ussd_string.downcase.split.include?('x'))
      @error_message = "Vous devez choisir 5 numéros"
      status = false
    end

    return status
  end

  def sportcash_main_menu
    @rendered_text = %Q[SPORTCASH
1- Sport
2- Top matchs
3- Dernière minute
4- Opportunités
5- Lives
6- Jouer
0- Retour
00- Accueil]
    @session_identifier = '49'
  end

  def set_session_identifier_sportcash_main_menu_selected
    @status = false
    if ['1', '2', '3', '4', '5', '6', '7', '0', '00'].include?(@ussd_string)
      @status = true
    else
      @rendered_text = %Q[SPORTCASH
1- Sport
2- Top matchs
3- Dernière minute
4- Opportunités
5- Lives
6- Jouer
0- Retour
00- Accueil]
      @session_identifier = '49'
    end
  end

  def list_sportcash_sports
    @list_sportcash_sports_request = Parameter.first.parionsdirect_url + "/ussd_spc/get_list_sport"
    @list_sportcash_sports_response = RestClient.get(@list_sportcash_sports_request) rescue ''
    sports_string = ""
    @sports_trash = "{"
    counter = 0

    sports = JSON.parse('{"sports":' + @list_sportcash_sports_response + '}') rescue nil
    sports = sports["sports"] rescue nil
    unless sports.blank?
      sports.each do |sport|
        counter += 1
        sports_string << counter.to_s + '- ' + %Q[#{sport["Description"]}
]
        @sports_trash << %Q["#{counter.to_s}":"#{sport["Description"]}|#{sport["Code"]}",]
      end
    end
    @sports_trash = @sports_trash.chop + "}"
    @rendered_text = %Q[SPORTCASH - Liste des sports
#{sports_string}
0- Retour
00- Accueil]
    @session_identifier = '50'
  end

  def set_session_identifier_depending_on_spc_sports_list_selected
    case @ussd_string
      when '0'
        back_to_list_spc_main_menu
      when '00'
        back_list_main_menu
      else
        @sport_name = JSON.parse(@current_ussd_session.list_spc_sport).assoc(@ussd_string)[1].split('|') rescue nil
        @spc_tournament_list_request = Parameter.first.parionsdirect_url + "/ussd_spc/get_tournaments_by_sport/#{@sport_name[0]}"
        @spc_tournament_list_response = RestClient.get(@spc_tournament_list_request) rescue ''
        if (JSON.parse(@spc_tournament_list_response)["Status"] rescue nil) == "ERROR"
          @list_sportcash_sports_request = Parameter.first.parionsdirect_url + "/ussd_spc/get_list_sport"
          @list_sportcash_sports_response = RestClient.get(@list_sportcash_sports_request) rescue ''
          sports_string = ""
          counter = 0

          sports = JSON.parse('{"sports":' + @list_sportcash_sports_response + '}') rescue nil
          sports = sports["sports"] rescue nil
          unless sports.blank?
            sports.each do |sport|
              counter += 1
              sports_string << counter.to_s + '- ' + %Q[#{sport["Description"]}
]
            end
          end
          @rendered_text = %Q[SPORTCASH - Liste des sports
Aucune donnée disponible
#{sports_string}
0- Retour
00- Accueil]
          @session_identifier = '50'
        else
          tournaments_string = ""
          @tournaments_trash = "{"
          counter = 0

          tournaments = JSON.parse('{"tournaments":' + @spc_tournament_list_response + '}') rescue nil
          tournaments = tournaments["tournaments"] rescue nil
          unless tournaments.blank?
            tournaments.each do |tournament|
              counter += 1
              tournaments_string << counter.to_s + '- ' + %Q[#{tournament["Descrition_Tourn"]}
]
              @tournaments_trash << %Q["#{counter.to_s}":"#{tournament["Descrition_Tourn"]}|#{tournament["Code_Tournois"]}",]
            end
          end
          @tournaments_trash = @tournaments_trash.chop + "}"
          @rendered_text = %Q[SPORTCASH
#{tournaments_string}
0- Retour
00- Accueil]
          @session_identifier = '51'
        end
      end
  end

  def set_session_identifier_depending_on_spc_sport_selected
    @tournament = JSON.parse(@current_ussd_session.tournaments_trash).assoc(@ussd_string)[1].split('|') rescue nil
    case @ussd_string
      when '0'
        back_to_list_spc_sports
      when '00'
        back_list_main_menu
      else
        @spc_event_list_request = Parameter.first.parionsdirect_url + "/ussd_spc/get_event_by_tourn_sport/#{@current_ussd_session.spc_sport_label}/#{@tournament[1]}"
        @spc_event_list_response = RestClient.get(@spc_event_list_request) rescue ''
        if (JSON.parse(@spc_event_list_response)["Status"] rescue nil) == "ERROR"
          tournaments_string = ""
          counter = 0

          tournaments = JSON.parse('{"tournaments":' + @spc_tournament_list_response + '}') rescue nil
          tournaments = tournaments["tournaments"] rescue nil
          unless tournaments.blank?
            tournaments.each do |tournament|
              counter += 1
              tournaments_string << counter.to_s + '- ' + %Q[#{tournament["Descrition_Tourn"]}
]
            end
          end
          @rendered_text = %Q[SPORTCASH
Aucune donnée disponible
#{tournaments_string}
0- Retour
00- Accueil]
          @session_identifier = '51'
        else
          events_string = ""
          @events_trash = "{"
          counter = 0

          events = JSON.parse('{"events":' + @spc_event_list_response + '}') rescue nil
          events = events["events"] rescue nil
          unless events.blank?
            events.each do |event|
              counter += 1
              events_string << counter.to_s + '- ' + %Q[#{event["Description_match"]} (#{event["Palcode"]}-#{event["Codevts"]})
]
              @events_trash << %Q["#{counter.to_s}":"#{event["Description_match"]}|#{event["Palcode"]}|#{event["Codevts"]}|#{event["Date_match"]}|#{event["Hour_match"]}",]
            end
          end
          @events_trash = @events_trash.chop + "}"
          @rendered_text = %Q[SPORTCASH
#{events_string}
0- Retour
00- Accueil]
          @session_identifier = '52'
        end
      end
  end

  def set_session_identifier_depending_on_spc_event_selected
    @event = JSON.parse(@current_ussd_session.events_trash).assoc(@ussd_string)[1].split('|') rescue nil
    case @ussd_string
      when '0'
        back_to_list_spc_tournaments
      when '00'
        back_list_main_menu
      else
        @spc_bet_type_request = Parameter.first.parionsdirect_url + "#{@current_ussd_session.spc_live == true ? '/ussd_spc/get_event_markets_live/' : '/ussd_spc/get_event_markets/'}#{@event[2] rescue 0}"
        @spc_bet_type_response = RestClient.get(@spc_bet_type_request) rescue ''
        if (JSON.parse(@spc_bet_type_response)["Status"] rescue nil) == "ERROR"
          @spc_event_list_request = Parameter.first.parionsdirect_url + "/ussd_spc/get_event_by_tourn_sport/#{@current_ussd_session.spc_sport_label}/#{@current_ussd_session.spc_tournament_code}"
          @spc_event_list_response = RestClient.get(@spc_event_list_request) rescue ''
          events_string = ""
          counter = 0

          events = JSON.parse('{"events":' + @spc_event_list_response + '}') rescue nil
          events = events["events"] rescue nil
          unless events.blank?
            events.each do |event|
              counter += 1
              events_string << counter.to_s + '- ' + %Q[#{event["Description_match"]} (#{event["Palcode"]}-#{event["Codevts"]})
]
            end
          end
          @rendered_text = %Q[SPORTCASH
Aucune donnée disponible
#{events_string}
0- Retour
00- Accueil]
          @session_identifier = '52'
        else
          bet_types_string = ""
          @bet_types_trash = "{"
          counter = 0

          bet_types = JSON.parse('{"bet_types":' + @spc_bet_type_response + '}') rescue nil
          bet_types = bet_types["bet_types"] rescue nil
          unless bet_types.blank?
            bet_types.each do |bet_type|
              counter += 1
              bet_types_string << counter.to_s + '- ' + %Q[#{bet_type["Bet_description"]}
]
              @bet_types_trash << %Q["#{counter.to_s}":"#{bet_type["Bet_code"]}|#{bet_type["Bet_description"]}|#{bet_type["Statut"]}",]
            end
          end
          @bet_types_trash = @bet_types_trash.chop + "}"
          @rendered_text = %Q[#{@event[0] rescue ''}
Faites vos pronostics. Choisissez votre pari :
#{bet_types_string}
0- Retour
00- Accueil]
          @session_identifier = '53'
        end
      end
  end

  def set_session_identifier_depending_on_bet_type_selected
    @bet_type = JSON.parse(@current_ussd_session.spc_bet_type_trash).assoc(@ussd_string)[1].split('|') rescue nil
    @current_ussd_session = @current_ussd_session
    case @ussd_string
      when '0'
        back_to_list_spc_events
      when '00'
        back_list_main_menu
      else
        @spc_draw_request = Parameter.first.parionsdirect_url + "#{@current_ussd_session.spc_live == true ? '/ussd_spc/get_event_markets_draws_live/' : '/ussd_spc/get_event_markets_draws/'}#{@current_ussd_session.spc_event_code}/#{@bet_type[0]}"
        @spc_draw_response = RestClient.get(@spc_draw_request) rescue ''
        if (JSON.parse(@spc_draw_response)["Status"] rescue nil) == "ERROR"
          @spc_bet_type_request = Parameter.first.parionsdirect_url + "#{@current_ussd_session.spc_live == true ? '/ussd_spc/get_event_markets_live/' : '/ussd_spc/get_event_markets/'}#{@current_ussd_session.spc_event_code}"
          @spc_bet_type_response = RestClient.get(@spc_bet_type_request) rescue ''
          bet_types_string = ""
          counter = 0

          bet_types = JSON.parse('{"bet_types":' + @spc_bet_type_response + '}') rescue nil
          bet_types = bet_types["bet_types"] rescue nil
          unless bet_types.blank?
            bet_types.each do |bet_type|
              counter += 1
              bet_types_string << counter.to_s + '- ' + %Q[#{bet_type["Bet_description"]}
]
            end
          end
          @rendered_text = %Q[#{@event[0] rescue ''}
Aucune donnée disponible
Faites vos pronostics. Choisissez votre pari :
#{bet_types_string}
0- Retour
00- Accueil]
          @session_identifier = '53'
        else
          draw_string = ""
          @draw_trash = "{"
          counter = 0

          draws = JSON.parse(@spc_draw_response) rescue nil
          draws = draws["odd_list"] rescue nil
          unless draws.blank?
            draws.each do |draw|
              counter += 1
              draw_string << counter.to_s + '- ' + %Q[#{draw["Bet_description"]}:#{(draw["Odd"]).to_f/100}
]
              @draw_trash << %Q["#{counter.to_s}":"#{draw["Draw code"]}|#{(draw["Odd"]).to_f/100}",]
            end
          end
          @draw_trash = @draw_trash.chop + "}"
          @rendered_text = %Q[SPORTCASH
#{@current_ussd_session.spc_event_description}
Faites vos pronostics. Choisissez votre cote:
#{draw_string}
0- Retour
00- Accueil]
          @session_identifier = '54'
        end
      end
  end

  def set_session_identifier_depending_on_spc_draw_selected
    @draw = JSON.parse(@current_ussd_session.spc_draw_trash).assoc(@ussd_string)[1].split('|') rescue nil
    case @ussd_string
      when '0'
        back_to_list_spc_bet_types
      when '00'
        back_list_main_menu
      else
        @spc_draw_description = @draw[0]
        @spc_odd = @draw[1]
        @rendered_text = %Q[Misez gros pour gagner GROS ! Entrez le montant de votre mise
0- Retour
00- Accueil]
        @session_identifier = '55'
      end
  end

  def spc_top_match
    @spc_event_list_request = Parameter.first.parionsdirect_url + "/ussd_spc/get_topmatch_list"
    @spc_event_list_response = RestClient.get(@spc_event_list_request) rescue ''
    if (JSON.parse(@spc_event_list_response)["Status"] rescue nil) == "ERROR"
      @rendered_text = %Q[Aucun match n'a été trouvé
SPORTCASH
1- Sport
2- Top matchs
3- Dernière minute
4- Opportunités
5- Lives
6- Jouer
0- Retour
00- Accueil]
      @session_identifier = '49'
    else
      events_string = ""
      @events_trash = "{"
      counter = 0

      events = JSON.parse('{"events":' + @spc_event_list_response + '}') rescue nil
      events = events["events"] rescue nil
      unless events.blank?
        events.each do |event|
          counter += 1
          events_string << counter.to_s + '- ' + %Q[#{event["Description_match"]} (#{event["Palcode"]}-#{event["Codevts"]})
]
          @events_trash << %Q["#{counter.to_s}":"#{event["Description_match"]}|#{event["Palcode"]}|#{event["Codevts"]}|#{event["Date_match"]}|#{event["Hour_match"]}",]
        end
        @events_trash = @events_trash.chop + "}"
      end
      @rendered_text = %Q[SPORTCASH
#{events_string}
0- Retour
00- Accueil]
      @session_identifier = '52'
    end
  end

  def spc_list_opportunities
    @spc_opportunities_list_request = Parameter.first.parionsdirect_url + "/ussd_spc/get_opportunity_list"
    @spc_opportunities_list_response = RestClient.get(@spc_opportunities_list_request) rescue ''
    if (JSON.parse(@spc_opportunities_list_response)["Status"] rescue nil) == "ERROR"
      @rendered_text = %Q[Aucune opportunité n'a été trouvée
SPORTCASH
1- Sport
2- Top matchs
3- Dernière minute
4- Opportunités
5- Lives
6- Jouer
0- Retour
00- Accueil]
      @session_identifier = '49'
    else
      opportunities_string = ""
      @opportunities_trash = "{"
      counter = 0

      opportunities = JSON.parse('{"opportunities":' + @spc_opportunities_list_response + '}') rescue nil
      opportunities = opportunities["opportunities"] rescue nil
      unless opportunities.blank?
        opportunities.each do |opportunity|
          counter += 1
          opportunities_string << counter.to_s + '- ' + %Q[#{opportunity["Championat"]} Mise: #{opportunity["Mise_opp"].to_s} Gain potentiel: #{opportunity["Gain_potentiel"].to_s})
]
          @opportunities_trash << %Q["#{counter.to_s}":"#{opportunity["Championat"]}|#{opportunity["Mise_opp"].to_s}|#{opportunity["Gain_potentiel"].to_s}|#{opportunity["List_Event"].join('|')}",]
        end
        @opportunities_trash = @opportunities_trash.chop + "}"
      end
      @rendered_text = %Q[SPORTCASH
#{opportunities_string}
0- Retour
00- Accueil]
      @session_identifier = '52-'
    end
  end

  def spc_list_opportunities_details
    case @ussd_string
      when '0'
        back_to_list_spc_main_menu
      when '00'
        back_list_main_menu
      else
        @opportunity = JSON.parse(@current_ussd_session.opportunities_trash).assoc(@ussd_string)[1].split('|') rescue nil
        @spc_combined = false
        @spc_combined_string = ""
        if @opportunity.blank?
          @spc_opportunities_list_request = Parameter.first.parionsdirect_url + "/ussd_spc/get_opportunity_list"
          @spc_opportunities_list_response = RestClient.get(@spc_opportunities_list_request) rescue ''
          opportunities_string = ""
          counter = 0

          opportunities = JSON.parse('{"opportunities":' + @spc_opportunities_list_response + '}') rescue nil
          opportunities = opportunities["opportunities"] rescue nil
          unless opportunities.blank?
            opportunities.each do |opportunity|
              counter += 1
              opportunities_string << counter.to_s + '- ' + %Q[#{opportunity["Championat"]} Mise: #{opportunity["Mise_opp"].to_s} Gain potentiel: #{opportunity["Gain_potentiel"].to_s})]
            end
          end
          @rendered_text = %Q[SPORTCASH
#{opportunities_string}]
          @session_identifier = '52-'
        else
          opp1 = @opportunity[3].split(',')
          opp2 = @opportunity[4].split(',')
          opp3 = @opportunity[5].split(',')
          opp4 = @opportunity[6].split(',')
          @spc_combined_string = %Q|
                    {
                      "bets": [
                        {
                          "pal_code":"#{opp1[1]}",
                          "event_code":"#{opp1[2]}",
                          "bet_code":"#{opp1[3]}",
                          "draw_code":"#{opp1[4]}",
                          "odd":"#{(opp1[5].to_f * 100).to_i}",
                          "begin_date":"#{opp1[6].gsub('-', '') rescue nil} #{opp1[7]}",
                          "teams":"#{opp1[0]}",
                          "sport":""
                        },
                        {
                          "pal_code":"#{opp2[1]}",
                          "event_code":"#{opp2[2]}",
                          "bet_code":"#{opp2[3]}",
                          "draw_code":"#{opp2[4]}",
                          "odd":"#{(opp2[5].to_f * 100).to_i}",
                          "begin_date":"#{opp2[6].gsub('-', '') rescue nil} #{opp2[7]}",
                          "teams":"#{opp2[0]}",
                          "sport":""
                        },
                        {
                          "pal_code":"#{opp3[1]}",
                          "event_code":"#{opp3[2]}",
                          "bet_code":"#{opp3[3]}",
                          "draw_code":"#{opp3[4]}",
                          "odd":"#{(opp3[5].to_f * 100).to_i}",
                          "begin_date":"#{opp3[6].gsub('-', '') rescue nil} #{opp3[7]}",
                          "teams":"#{opp3[0]}",
                          "sport":""
                        },
                        {
                          "pal_code":"#{opp4[1]}",
                          "event_code":"#{opp4[2]}",
                          "bet_code":"#{opp4[3]}",
                          "draw_code":"#{opp4[4]}",
                          "odd":"#{(opp4[5].to_f * 100).to_i}",
                          "begin_date":"#{opp4[6].gsub('-', '') rescue nil} #{opp4[7]}",
                          "teams":"#{opp4[0]}",
                          "sport":""
                        }
                      ],
                      "amount":"400",
                      "formula":"COMBINE"
                    }
                  |
          @rendered_text = %Q[SPORTCASH - Veuillez entrer votre code secret de compte de jeu pour valider
#{@opportunity[0]}
#{opp1[0]} (#{opp1[1]} - #{opp1[2]})
#{opp2[0]} (#{opp2[1]} - #{opp2[2]})
#{opp3[0]} (#{opp3[1]} - #{opp3[2]})
#{opp4[0]} (#{opp4[1]} - #{opp4[2]})]
          @session_identifier = '56'
          @spc_combined = true
        end
      end
  end

  def spc_last_minute_match
    @spc_event_list_request = Parameter.first.parionsdirect_url + "/ussd_spc/get_last_min_match"
    @spc_event_list_response = RestClient.get(@spc_event_list_request) rescue ''
    if (JSON.parse(@spc_event_list_response)["Status"] rescue nil) == "ERROR"
      @rendered_text = %Q[Aucun match n'a été trouvé
SPORTCASH
1- Sport
2- Top matchs
3- Dernière minute
4- Opportunités
5- Lives
6- Jouer
0- Retour
00- Accueil]
      @session_identifier = '49'
    else
      @spc_event_list_response = RestClient.get(@spc_event_list_request) rescue ''
      events_string = ""
      @events_trash = "{"
      counter = 0

      events = JSON.parse('{"events":' + @spc_event_list_response + '}') rescue nil
      events = events["events"] rescue nil
      unless events.blank?
        events.each do |event|
          counter += 1
          events_string << counter.to_s + '- ' + %Q[#{event["Description_match"]} (#{event["Palcode"]}-#{event["Codevts"]})
]
          @events_trash << %Q["#{counter.to_s}":"#{event["Description_match"]}|#{event["Palcode"]}|#{event["Codevts"]}|#{event["Date_match"]}|#{event["Hour_match"]}",]
        end
        @events_trash = @events_trash.chop + "}"
      end
      @rendered_text = %Q[SPORTCASH
#{events_string}
0- Retour
00- Accueil]
      @session_identifier = '52'
    end
  end

  def spc_live_match
    @spc_event_list_request = Parameter.first.parionsdirect_url + "/ussd_spc/get_live_match_list"
    @spc_event_list_response = RestClient.get(@spc_event_list_request) rescue ''
    if (JSON.parse(@spc_event_list_response)["Status"] rescue nil) == "ERROR"
      @rendered_text = %Q[Aucun match n'a été trouvé
SPORTCASH
1- Sport
2- Top matchs
3- Dernière minute
4- Opportunités
5- Lives
6- Jouer
0- Retour
00- Accueil]
      @session_identifier = '49'
    else
      @spc_live = true
      @spc_event_list_response = RestClient.get(@spc_event_list_request) rescue ''
      events_string = ""
      @events_trash = "{"
      counter = 0

      events = JSON.parse('{"events":' + @spc_event_list_response + '}') rescue nil
      events = events["events"] rescue nil
      unless events.blank?
        events.each do |event|
          counter += 1
          events_string << counter.to_s + '- ' + %Q[#{event["description_match"]} (#{event["Palcode"]}-#{event["Codevts"]})
]
          @events_trash << %Q["#{counter.to_s}":"#{event["description_match"]}|#{event["Palcode"]}|#{event["Codevts"]}|#{event["Date_match"]}|#{event["Hour_match"]}",]
        end
        @events_trash = @events_trash.chop + "}"
      end
      @rendered_text = %Q[SPORTCASH
#{events_string}
0- Retour
00- Accueil]
      @session_identifier = '52'
    end
  end

  def spc_get_event_code
    @rendered_text = %Q[SPORTCASH
Veuillez entrer le code évènement
0- Retour
00- Accueil]
      @session_identifier = '49-'
  end

  def spc_play
    case @ussd_string
      when '0'
        back_to_list_spc_main_menu
      when '00'
        back_list_main_menu
      else
        @spc_bet_type_request = Parameter.first.parionsdirect_url + "#{@current_ussd_session.spc_live == true ? '/ussd_spc/get_event_markets_live/' : '/ussd_spc/get_event_markets/'}#{@ussd_string rescue 0}"
        @spc_bet_type_response = RestClient.get(@spc_bet_type_request) rescue ''
        @spc_event_info_request = Parameter.first.parionsdirect_url + "/ussd_spc/get_event_info/#{@ussd_string rescue 0}"
        @spc_event_info_response = RestClient.get(@spc_event_info_request) rescue ''

        if (JSON.parse(@spc_bet_type_response)["Status"] rescue nil) == "ERROR" || (JSON.parse(@spc_event_info_response)["Status"] rescue nil) == "ERROR"
          @rendered_text = %Q[Aucun match n'a été trouvé
SPORTCASH
1- Sport
2- Top matchs
3- Dernière minute
4- Opportunités
5- Lives
6- Jouer
0- Retour
00- Accueil]
          @session_identifier = '49'
        else
          bet_types_string = ""
          @bet_types_trash = "{"
          counter = 0

          bet_types = JSON.parse('{"bet_types":' + @spc_bet_type_response + '}') rescue nil
          bet_types = bet_types["bet_types"] rescue nil
          event_info = JSON.parse('{"event":' + @spc_event_info_response + '}')["event"].first rescue nil
          unless bet_types.blank? && event_info.blank?
            bet_types.each do |bet_type|
              counter += 1
              bet_types_string << counter.to_s + '- ' + %Q[#{bet_type["Bet_description"]}
]
              @bet_types_trash << %Q["#{counter.to_s}":"#{bet_type["Bet_code"]}|#{bet_type["Bet_description"]}|#{bet_type["Statut"]}",]
            end
            @spc_event_description = event_info["Description_match"]
            @spc_event_pal_code = event_info["Palcode"]
            @spc_event_code = event_info["Codevts"]
            @spc_event_date = event_info["Date_match"]
            @spc_event_time = event_info["Hour_match"]
          end
          @bet_types_trash = @bet_types_trash.chop + "}"
          @rendered_text = %Q[#{@spc_event_description}
Faites vos pronostics. Choisissez votre pari :
#{bet_types_string}
0- Retour
00- Accueil]
          @session_identifier = '53'
        end
      end
  end

  def spc_validate_stake
    if not_a_number?(@ussd_string) || @ussd_string.to_i <= 0
      @rendered_text = %Q[Misez gros pour gagner GROS ! Entrez le montant de votre mise
0- Retour
00- Accueil]
      @session_identifier = '55'
    else
      @spc_stake = @ussd_string
      @rendered_text = %Q[Veuillez entrer votre code secret de compte de jeu pour prendre le pari.
VOTRE COUPON:
Equipes: #{@current_ussd_session.spc_event_description}
#{@current_ussd_session.spc_bet_description}
Côte: #{@current_ussd_session.spc_odd.to_f}
Mise: #{@ussd_string}
Gain probable: #{@ussd_string.to_f * @current_ussd_session.spc_odd.to_f}
0- Retour
00- Accueil]
      @session_identifier = '56'
    end
  end

  def spc_place_bet
    @get_gamer_id_request = Parameter.first.gateway_url + "/8ba869a7a9c59f3a0/api/users/gamer_id/#{@account_profile.msisdn}"
    @get_gamer_id_response = Typhoeus.get(@get_gamer_id_request, connecttimeout: 30)
    if @get_gamer_id_response.body.blank?
      @rendered_text = %Q[VOTRE COUPON:
Veuillez entrer votre code secret de compte de jeu pour prendre le pari.
Equipes: #{@current_ussd_session.spc_event_description}
#{@current_ussd_session.spc_bet_description}
Côte: #{@current_ussd_session.spc_odd.to_f}
Mise: #{@current_ussd_session.spc_stake.to_f}
Gain probable: #{@current_ussd_session.spc_stake.to_f * @current_ussd_session.spc_odd.to_f}
0- Retour
00- Accueil]
      @session_identifier = '56'
    else
      @event = JSON.parse(@current_ussd_session.events_trash).assoc(@ussd_string)[1].split('|') rescue nil
      @spc_place_bet_url = Parameter.first.gateway_url + "/spc/api/6d3782c78d/m_coupon/sell/#{@get_gamer_id_response.body}/#{@account_profile.paymoney_account_number}/#{@ussd_string}"
      if @current_ussd_session.spc_combined == true
        @request_body = @current_ussd_session.spc_combined_string
      else
        @request_body = %Q|
                  {
                    "bets": [
                      {
                        "pal_code":"#{@current_ussd_session.spc_event_pal_code}",
                        "event_code":"#{@current_ussd_session.spc_event_code}",
                        "bet_code":"#{@current_ussd_session.spc_bet_code}",
                        "draw_code":"#{@current_ussd_session.spc_draw_description}",
                        "odd":"#{(@current_ussd_session.spc_odd.to_f * 100).to_i}",
                        "begin_date":"#{@current_ussd_session.spc_event_date.gsub('-', '') rescue nil} #{@current_ussd_session.spc_event_time}",
                        "teams":"#{@current_ussd_session.spc_event_description}",
                        "sport":"#{@current_ussd_session.spc_sport_label}"
                      }
                    ],
                    "amount":"#{@current_ussd_session.spc_stake}",
                    "formula":"SIMPLE"
                  }
                |
      end
      request = Typhoeus::Request.new(
      @spc_place_bet_url,
      method: :post,
      body: @request_body
      )
      request.run
      @spc_place_bet_response = request.response

      json_object = JSON.parse(@spc_place_bet_response.body)["bet"].first rescue nil
      if json_object.blank?
        @rendered_text = %Q[Votre pari n'a pas pu etre placé.
Veuillez entrer votre code secret de compte de jeu pour prendre le pari.
Equipes: #{@current_ussd_session.spc_event_description}
#{@current_ussd_session.spc_bet_description}
Côte: #{@current_ussd_session.spc_odd.to_f}
Mise: #{@current_ussd_session.spc_stake.to_f}
Gain probable: #{@current_ussd_session.spc_stake.to_f * @current_ussd_session.spc_odd.to_f}
0- Retour
00- Accueil]
        @session_identifier = '56'
      else
        if json_object["error"].blank?
          @rendered_text = %Q|FELICITATIONS, votre pari a bien été  enregistré. N° ticket : #{json_object["ticket_id"] rescue ''} / Gain probable: #{json_object["amount_win"] rescue ''}
1- Sport
2- Top matchs
3- Dernière minute
4- Opportunités
5- Lives
6- Calendrier
7- Jouer
0- Retour
00- Accueil|
          @session_identifier = '49'
        else
          @rendered_text = %Q[Votre pari n'a pas pu etre placé.
Veuillez entrer votre code secret de compte de jeu pour prendre le pari.
Equipes: #{@current_ussd_session.spc_event_description}
#{@current_ussd_session.spc_bet_description}
Côte: #{@current_ussd_session.spc_odd.to_f}
Mise: #{@current_ussd_session.spc_stake.to_f}
Gain probable: #{@current_ussd_session.spc_stake.to_f * @current_ussd_session.spc_odd.to_f}
0- Retour
00- Accueil]
        @session_identifier = '56'
        end
      end
    end
  end

  def display_parions_direct_web_link
    @rendered_text = %Q[Aller sur le lien pour télécharger
www.parionsdirect.ci
0- Retour]
    @session_identifier = '6--'
  end

  def display_parions_direct_apk_link
    @rendered_text = %Q[Aller sur le lien pour télécharger
www.parionsdirect.ci/apk
0- Retour]
    @session_identifier = '6--'
  end

  def display_parions_direct_windows_phone_link
    @rendered_text  = %Q[Aller sur le lien pour télécharger
www.parionsdirect.ci/windows-phone
0- Retour]
    @session_identifier = '6--'
  end

  def display_parions_direct_main_ussd_menu
    @rendered_text = %Q[1- Jeux
2- Mes paris
3- Mon solde
4- Rechargement
5- Votre service SMS
6- Mes OTP
7- Mes comptes
8- Retrait vers MTN MOBILE MONEY]
    @session_identifier = '5'
  end

  def display_parions_direct_gaming_chanels
    @rendered_text = %Q[Choisissez votre canal de jeux
1- USSD
2- WEB
3- ANDROID
4- WINDOWS]
    @session_identifier = '6--'
  end

  def reload_paymoney_with_mtn_money
    @rendered_text = %Q[1- Recharger mon compte de jeu
2- Recharger autre compte de jeu
0- Retour
00- Accueil]
    @session_identifier = '7--'
  end

  def enter_other_account_mtn_reload_account_number
    case @ussdtring
      when '0'
        back_list_main_menu
      when '00'
        back_list_main_menu
      else
        @rendered_text = %Q[Saisissez le numéro de compte de jeu à recharger
0- Retour
00- Accueil]
        @session_identifier = '8--'
      end
  end

  def enter_mtn_reload_amount
    case @ussdtring
      when '0'
        back_list_main_menu
      when '00'
        back_list_main_menu
      else
        @rendered_text = %Q[Saisissez le montant du rechargement
0- Retour
00- Accueil]
        @session_identifier = '9--'
      end
  end

  def display_mtn_reload_amount_with_fee
    if not_a_number?(@ussd_string)
      @rendered_text = %Q[Le montant du rechargement n'est pas valide
Saisissez le montant du rechargement
0- Retour
00- Accueil]
      @session_identifier = '9--'
    else
      case @ussdtring
        when '0'
          @rendered_text = %Q[Saisissez le numéro de compte de jeu à recharger
0- Retour
00- Accueil]
          @session_identifier = '8--'
        when '00'
          back_list_main_menu
        else
          @rendered_text = %Q[Montant recharge: #{@ussd_string} FCFA
Frais: #{(@ussd_string.to_f * 0.02).floor} FCFA
1- Confirmer
0- Retour]
          @session_identifier = '9---'
        end
    end
  end

  def get_reload_account
    @check_pw_account_url = Parameter.first.paymoney_url + "/PAYMONEY_WALLET/rest/check2_compte/#{@ussd_string}"
    @check_pw_account_response = Typhoeus.get(@check_pw_account_url, connecttimeout: 30)

    if !@check_pw_account_response.body.blank? && @check_pw_account_response.body != 'null'
      @rendered_text = %Q[Saisissez le montant du rechargement
0- Retour
00- Accueil]
      @session_identifier = '9--'
    else
      @rendered_text = %Q[Saisissez le numéro de compte de jeu à recharger
0- Retour
00- Accueil]
      @session_identifier = '8--'
    end
  end

  def proceed_reloading
    if not_a_number?(@ussd_string)
      @rendered_text = %Q[Le montant du rechargement n'est pas valide
Saisissez le montant du rechargement
0- Retour
00- Accueil]
      @session_identifier = '9--'
    else
      case @ussd_string
        when '0'
          @rendered_text = %Q[Saisissez le montant du rechargement
0- Retour
00- Accueil]
          @session_identifier = '9--'
        when '00'
          back_list_main_menu
        else
          @reload_request = "#{Parameter.first.back_office_url rescue ""}/MTNCI/ussd/reload/8f90aaece362b6d83b6887cc19067433/75592949-2b13-4175-b811-3caf75687355/#{Digest::SHA1.hexdigest([DateTime.now.iso8601(6), rand].join).hex.to_s[0..8]}/225#{@msisdn[-8,8]}/#{@current_ussd_session.reload_amount}/XOF/#{@current_ussd_session.reload_account.blank? ? AccountProfile.find_by_msisdn(@msisdn[-8,8]).paymoney_account_number : @current_ussd_session.reload_account}"
          @reload_response = RestClient.get(@reload_request) rescue ''

          if @reload_response == '2'
            @rendered_text = %Q[Votre demande de rechargement est en cours de traitement. Montant : #{@current_ussd_session.reload_amount} FCFA.]
            @session_identifier = '7--'
            @reload = true
          else
            if @reload_response == '-1'
              @rendered_text = %Q[Fond insuffisant. Veuillez vérifier puis saisissez le montant du rechargement
0- Retour
00- Accueil]
              @session_identifier = '9--'
            else
              @rendered_text = %Q[La transaction a échoué, Veuillez réessayer
Saisissez le montant du rechargement.
0- Retour
00- Accueil]
              @session_identifier = '9--'
            end
          end
        end
    end
  end

  def enter_mtn_unload_amount
    @rendered_text = %Q[Saisissez le montant du Retrait vers MTN MOBILE MONEY
0- Retour
00- Accueil]
    @session_identifier = '10--'
  end

  def get_unload_amount
    if not_a_number?(@ussd_string)
      @rendered_text = %Q[Le montant du Retrait vers MTN MOBILE MONEY n'est pas valide
Saisissez le montant du Retrait vers MTN MOBILE MONEY
0- Retour
00- Accueil]
      @session_identifier = '10--'
    else
      if @ussd_string == '0'
        @rendered_text = %Q[1- Jeux
2- Mes paris
3- Mon solde
4- Rechargement
5- Votre service SMS
6- Mes OTP
7- Mes comptes
8- Retrait vers MTN MOBILE MONEY]
      @session_identifier = '5'
      else
        fee = RestClient.get("#{Parameter.first.wallet_url rescue ""}/api/1314a3dfb72826290bbc99c71b510d2b/fee/d2dff0/#{@ussd_string}") rescue ''
        @rendered_text = %Q[Votre compte de jeu sera débité de:
Montant: #{@ussd_string} FCFA
Frais: #{fee}
Veuillez saisir le code secret de votre compte de jeu
0- Retour
00- Accueil]
        @session_identifier = '11--'
      end
    end
  end

  def proceed_unloading
    if @ussd_string.blank?
      fee = RestClient.get("#{Parameter.first.wallet_url rescue ""}/api/1314a3dfb72826290bbc99c71b510d2b/fee/d2dff0/#{@ussd_string}") rescue ''
      @rendered_text = %Q[Votre compte de jeu sera débité de:
Montant: #{@ussd_string} FCFA
Frais: #{fee}
Veuillez saisir le code secret de votre compte de jeu
0- Retour
00- Accueil]
      @session_identifier = '11--'
    else
      case @ussd_string
        when '0'
          @rendered_text = %Q[Saisissez le montant du Retrait vers MTN MOBILE MONEY
0- Retour
00- Accueil]
          @session_identifier = '10--'
        when '00'
          back_list_main_menu
        else
          @unload_request = "#{Parameter.first.back_office_url rescue ""}/MTNCI/ussd/unload/8f90aaece362b6d83b6887cc19067433/75592949-2b13-4175-b811-3caf75687002/#{Digest::SHA1.hexdigest([DateTime.now.iso8601(6), rand].join).hex.to_s[0..8]}/225#{@msisdn[-8,8]}/#{@current_ussd_session.unload_amount}/XOF/#{@current_ussd_session.unload_account.blank? ? AccountProfile.find_by_msisdn(@msisdn[-8,8]).paymoney_account_number : @current_ussd_session.unload_account}/#{@ussd_string}"
          @unload_response = RestClient.get(@unload_request) rescue ''
          if @unload_response == '1'
            @rendered_text = %Q[Votre transaction a été effectuée avec succès. Montant : #{@current_ussd_session.unload_amount} FCFA.]
            @session_identifier = '11--'
          else
            if @unload_response == '-1'
              @rendered_text = %Q[Fond insuffisant. Veuillez vérifier puis saisissez le montant du Retrait vers MTN MOBILE MONEY
0- Retour
00- Accueil]
              @session_identifier = '10--'
            else
              @rendered_text = %Q[La transaction a échoué, Veuillez réessayer
Saisissez le montant du Retrait vers MTN MOBILE MONEY
0- Retour
00- Accueil]
              @session_identifier = '10--'
            end
          end
        end
    end
  end

end
