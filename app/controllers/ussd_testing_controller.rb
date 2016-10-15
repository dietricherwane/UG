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
          UssdSession.create(session_identifier: @session_identifier, sender_cb: @sender_cb, parionsdirect_password_url: @parionsdirect_password_url, parionsdirect_password_response: @parionsdirect_password_response.body, parionsdirect_password: @password, parionsdirect_salt: @salt)
        else
          # Saisie du mot de passe de création de compte parionsdirect
          if @current_ussd_session.session_identifier == '1'
            set_parionsdirect_password
            @current_ussd_session.update_attributes(session_identifier: @session_identifier, creation_pd_password: @creation_pd_password)
          end
          if @current_ussd_session.session_identifier == '2'
            check_parionsdirect_password
            @current_ussd_session.update_attributes(session_identifier: @session_identifier, connection_pd_pasword: @ussd_string)
          end
          # Saisie de la confirmation du mot de passe de création de compte parionsdirect
          if @current_ussd_session.session_identifier == '3'
            create_parionsdirect_and_paymoney_account
            @current_ussd_session.update_attributes(session_identifier: @session_identifier, creation_pd_password: @creation_pd_password, creation_pd_password_confirmation: @creation_pd_password_confirmation, creation_pd_request: @creation_pd_request, creation_pd_response: @creation_pd_response.body, pd_account_created: @pd_account_created, creation_pw_request: @creation_pw_request, creation_pw_response: @creation_pw_response.body, pw_account_created: @pw_account_created)
          end
        end

        send_ussd(@operation_type, @msisdn, @sender_cb, @linkid, @rendered_text)
      end
    end
  end

  def authenticate_or_create_parionsdirect_account(msisdn)
    @parionsdirect_password_url = Parameter.first.gateway_url + "/85fg69a7a9c59f3a0/api/users/password/#{msisdn[-8,8] rescue 0}"
    @parionsdirect_password_response = Typhoeus.get(@parionsdirect_password_url, connecttimeout: 30)
    password = @parionsdirect_password_response.body.split('-') rescue nil
    @password = password[0] rescue nil
    @salt = password[1] rescue nil

    if password.blank?
      # Le client n'a pas de compte parionsdirect et doit en créer un
      @rendered_text = %Q[Veuillez entrer un mot de passe.]
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
        @rendered_text = %Q[
          Veuillez saisir votre numéro de compte Paymoney.
          ]
        @session_identifier = '4'
      else
        @rendered_text = %Q[
          Le mot de passe saisi n'est pas valide
          Veuillez entrer votre mot de passe parionsdirect.
          ]
        @session_identifier = '2'
      end
    end
  end

  # Création d'un nouveau compte parionsdirect par saisie du mot de passe
  def set_parionsdirect_password
    # L'utilisateur n'a pas saisi de mot de passe, on le ramène au menu précédent
    if @ussd_string.blank?
      # Le client n'a pas de compte parionsdirect et entrer un mot de passe pour en créer un
      @rendered_text = %Q[Veuillez entrer un mot de passe.]
      @session_identifier = '1'
    else
      @creation_pd_password = @ussd_string
      # Le client n'a pas de compte parionsdirect et confirmer le mot de passe pour en créer un
      @rendered_text = %Q[Veuillez confirmer le mot de passe précédemment entré.]
      @session_identifier = '3'
    end
  end

  # Création d'un nouveau compte parionsdirect par confirmation du mot de passe et création d'un compte paymoney
  def create_parionsdirect_and_paymoney_account
    # L'utilisateur n'a pas saisi de confirmation de mot de passe, on le ramène au menu précédent
    if @ussd_string.blank?
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
            Une erreur s'est produite lors de la création du compte Paymoney
            Veuillez confirmer le mot de passe précédemment entré.
            ]
          @session_identifier = '3'
        else
          @pd_account_created = true
          # Création du compte paymoney
          @creation_pw_request = Parameter.first.paymoney_url + "/PAYMONEY_WALLET/rest/ussd_create_compte/#{@msisdn[-8,8]}"
          @creation_pw_response = Typhoeus.get(@creation_pw_request, connecttimeout: 30)
          paymoney_account = JSON.parse(@creation_pw_response.body) rescue nil
          # Le compte paymoney a été créé
          if (paymoney_account["errors"] rescue nil).blank?
            @pw_account_created = true
            @rendered_text = %Q[
              Veuillez saisir votre numéro de compte Paymoney.
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
        end
      end
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
end
