class UssdTestingController < ApplicationController

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

    MtnStartSessionLog.create(operation_type: "Stop session", request_url: url, request_log: request_body, response_log: start_session_response.body, request_code: start_session_response.code, total_time: start_session_response.total_time, request_headers: start_session_response.headers.to_s, error_code: error_code, error_message: error_message, status: status)

    render text: stop_session_response.body
  end

  def main_menu
    @raw_body = request.body.read rescue nil
    @received_body = (Nokogiri.XML(@raw_body) rescue nil)
    @error_code = '0'
    @error_message = ''

    c_main_menu_parse_xml

    if @error_code.blank?
      main_menu_parse_xml

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
    end

    UssdReceptionLog.create(received_parameters: @raw_body)
    result = %Q[
            <soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:loc="http://www.csapi.org/schema/parlayx/ussd/notification/v1_0/local">
              <soapenv:Header/>
              <soapenv:Body>
                <loc:notifyUssdReceptionResponse>
                  <loc:result>#{@error_code}</loc:result>
                </loc:notifyUssdReceptionResponse>
              </soapenv:Body>
            </soapenv:Envelope>
          ]

    send_ussd

    render :xml => result
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
      @error_message = "Le serviceCode est vide"
    end
  end

  def main_menu_parse_xml
    @rev_id = @received_body.xpath('//ns1:NotifySOAPHeader').at('ns1:spRevId').content rescue nil
    @rev_password = @received_body.xpath('//ns1:NotifySOAPHeader').at('ns1:spRevpassword').content rescue nil
    @sp_id = @received_body.xpath('//ns1:NotifySOAPHeader').at('ns1:spId').content rescue nil
    @service_id = @received_body.xpath('//ns1:NotifySOAPHeader').at('ns1:serviceId').content rescue nil
    @timestamp = @received_body.xpath('//ns1:NotifySOAPHeader').at('ns1:timeStamp').content rescue nil
    @unique_id = @received_body.xpath('//ns1:NotifySOAPHeader').at('ns1:traceUniqueID').content rescue nil

    @msg_type = @received_body.xpath('//ns2:notifyUssdReception').at('ns2:msgType').content rescue nil
    @sender_cb = @received_body.xpath('//ns2:notifyUssdReception').at('ns2:senderCB').content rescue nil
    @receive_cb = @received_body.xpath('//ns2:notifyUssdReception').at('ns2:receiveCB').content rescue nil
    @ussd_op_type = @received_body.xpath('//ns2:notifyUssdReception').at('ns2:ussdOpType').content rescue nil
    @msisdn = @received_body.xpath('//ns2:notifyUssdReception').at('ns2:msIsdn').content rescue nil
    @service_code = @received_body.xpath('//ns2:notifyUssdReception').at('ns2:serviceCode').content rescue nil
    @code_scheme = @received_body.xpath('//ns2:notifyUssdReception').at('ns2:codeScheme').content rescue nil
    @ussd_string = @received_body.xpath('//ns2:notifyUssdReception').at('ns2:ussdString').content rescue nil
  end

  def send_ussd
    url = '196.201.33.108:8310/SendUssdService/services/SendUssd'
    sp_id = '2250110000460'
    service_id = '225012000003070'
    password = 'bmeB500'
    timestamp = DateTime.now.strftime('%Y%m%d%H%M%S')
    sp_password = Digest::MD5.hexdigest(sp_id + password + timestamp)
    oa = @msisdn
    fa = @msisdn
    link_id = ''
    present_id = ''
    msg_type = '0'
    receive_cb = '0XFFFFFFFF'
    sender_cb = Digest::SHA1.hexdigest([DateTime.now.iso8601(6), rand].join).hex.to_s[0..7]
    ussd_op_type = '1'
    msisdn = @msisdn
    service_code = '218'
    code_scheme = '15'
    ussd_string = %Q[
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
      <soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:loc="http://www.csapi.org/schema/parlayx/ussd/send/v1_0/local">
        <soapenv:Header>
          <tns:RequestSOAPHeader xmlns:tns="http://www.huawei.com.cn/schema/common/v2_1">
            <tns:spId>#{sp_id}</tns:spId>
            <tns:spPassword>#{sp_password}</tns:spPassword>
            <tns:bundleID></tns:bundleID>
            <tns:timeStamp>#{timestamp}</tns:timeStamp>
            <tns:OA>#{@msisdn}</tns:OA>
            <tns:FA>#{@msisdn}</tns:FA>
          </tns:RequestSOAPHeader>
        </soapenv:Header>
        <soapenv:Body>
          <loc:sendUssd>
            <loc:msgType>0</loc:msgType>
            <loc:senderCB>306909975</loc:senderCB>
            <loc:receiveCB/>
            <loc:ussdOpType>1</loc:ussdOpType>
            <loc:msIsdn>#{@msisdn}</loc:msIsdn>
            <loc:serviceCode>#{service_code}</loc:serviceCode>
            <loc:codeScheme>#{code_scheme}</loc:codeScheme>
            <loc:ussdString>#{ussd_string}</loc:ussdString>
          </loc:sendUssd>
        </soapenv:Body>
      </soapenv:Envelope>
    ]

    send_ussd_response = Typhoeus.post(url, body: request_body, connecttimeout: 30)

    nokogiri_response = (Nokogiri.XML(send_ussd_response.body) rescue nil)

    error_code = nokogiri_response.xpath('//soapenv:Fault').at('faultcode').content rescue nil
    error_message = nokogiri_response.xpath('//soapenv:Fault').at('faultstring').content rescue nil

    if error_code.blank?
      status = true
    else
      status = false
    end

    MtnStartSessionLog.create(operation_type: "Send ussd", request_url: url, request_log: request_body, response_log: send_ussd_response.body, request_code: send_ussd_response.code, total_time: send_ussd_response.total_time, request_headers: send_ussd_response.headers.to_s, error_code: error_code, error_message: error_message, status: status)
  end

end
