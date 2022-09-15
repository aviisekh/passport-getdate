#!/Users/aviisekh/.rbenv/shims/ruby

require 'net/http'
require 'uri'
require 'json'
require 'date'
require 'pry-rails'

class DateMaker
  attr_reader :http

  APPOINTMENT_DATE = "2022-09-15"
  TIME_SLOT = "13:30"
  LOCATION_ID = 21
  ENROLLMENT_CENTER_COE = "DOP"

  def initialize(appointment_date: APPOINTMENT_DATE, time_slot: TIME_SLOT, location_id: LOCATION_ID, enrollment_center_code: ENROLLMENT_CENTER_COE)
    @appointment_date = appointment_date 
    @time_slot = time_slot
    @location_id = location_id 
    @enrollment_center_code = enrollment_center_code 
  end

  def get_calendar(location_id: LOCATION_ID)
    @uri = URI.parse("https://emrtds.nepalpassport.gov.np/iups-api/calendars/#{location_id}/false")
    response = http.request(get_request)
    p JSON.parse(response.body)
  end

  def get_time_slots(date: APPOINTMENT_DATE)
    @uri = URI.parse("https://emrtds.nepalpassport.gov.np/iups-api/timeslots/#{@location_id}/#{date}/false")

    response = http.request(get_request)
    p JSON.parse(response.body)
  end

  def get_appointment(date: APPOINTMENT_DATE, time_slot: TIME_SLOT, location_id: LOCATION_ID)
    appointment_id = nil
    @uri = URI.parse("https://emrtds.nepalpassport.gov.np/iups-api/appointments")
    @body =  {"id":"null", "appointmentDate": date, "timeSlot": time_slot, "locationId":location_id, "isVip":false}
    
    while true do 
      sleep(1)
      begin 
        response = http.request(post_request)
        if response.code == "200"
          appointment_id = JSON.parse(response.body)
          p "Appointment ID: #{appointment_id}"
          break
        else
          p "New status code #{response.code}."
          p response.body
          p "Trying again..."
        end
      rescue
        p "Failed, Trying again..."
      end
    end

    return appointment_id
  end

  def submit_form(appointment_id: nil)

    @uri = URI.parse("https://emrtds.nepalpassport.gov.np/iups-api/eservices/perform/")
    @location = "c96878d9dc2740e89e11c7727c73367d"
    appointment_data = {"id": "", "appointmentDate": APPOINTMENT_DATE, "timeSlot": TIME_SLOT, "locationId": LOCATION_ID, "isVip": false}

    @body = get_form_body.merge!(appointment: appointment_data)

    while true do 
      sleep(1)
      begin 
        response = http.request(post_request)
        if response.code == "200"
          p "Success!!!: #{JSON.parse(response.body)}"
          break
        else
          p "New status code #{response.code}."
          p response.body
          p "Trying again..."
        end
      rescue
        p "Failed, Trying again..."
      end
    end
  end

  def upload_files
    @uri = URI.parse('https://emrtds.nepalpassport.gov.np/iups-api/scan')
  end


  def get_followup(request_number, birthdate)
    @uri = URI.parse("https://emrtds.nepalpassport.gov.np/iups-api/eservices/followup/")
    @body = {"requestNumber": request_number, "birthDate": birthdate}
    while true do 
      sleep(1)
      begin 
        response = http.request(post_request)
        if response.code == "200"
          p "Success!!!: #{JSON.parse(response.body)}"
          break
        else
          p "New status code #{response.code}."
          p response.body
          p "Trying again..."
        end
      rescue
        p "Failed, Trying again..."
      end
    end
  end

  private
  def get_request
    Net::HTTP::Get.new(@uri.request_uri)
  end

  def post_request 
    request = Net::HTTP::Post.new(@uri.request_uri)
    request.content_type = "application/json"
    request.body = JSON.dump(@body)
    request["location"] = @location unless @location.nil?

    request
  end

  def http
    http = Net::HTTP.new(@uri.host, @uri.port)
    http.use_ssl = true
    http.verify_mode = OpenSSL::SSL::VERIFY_PEER
    http
  end

  def get_form_body 
    { 
      "version":"0",
      "preEnrollApplId":"",
      "documentTypeOthers":"test",
      "lastName":"GHARTI MAGAR",
      "firstName":"URILA",
      "birthCountry":"NPL",
      "dateOfBirth":"2000-02-22",
      "dateOfBirthBS":"2056-11-10",
      "birthDistrict":"BAG",
      "citizenIssuePlaceDistrict":"BAG",
      "contactLastName":"BAHADUR GHARTI",
      "contactFirstName":"DAL",
      "mainAddressCountry":"NPL",
      "citizenIssueDateBS":"2073-06-17",
      "gender":"F",
      "nationality":"NPL",
      "fatherLastName":"BAHADUR GHARTI",
      "fatherFirstName":"DAL",
      "motherLastName":"KUMARI GHARTI",
      "motherFirstName":"MAN",
      "homePhone":"+977 9840219173",
      "email":"urilagharti2@gmail.com",
      "contactMunicipality":"BAG-DRP00A",
      "contactCountry":"NPL",
      "contactDistrict":"BAG",
      "mainAddressWard":"7",
      "contactWard":"7",
      "mainAddressMunicipality":"BAG-DRP00A",
      "mainAddressDistrict":"BAG",
      "mainAddressProvince":"GDK",
      "contactProvince":"GDK",
      "mainAddressStreetVillage":"BOBANG",
      "nin":"8577359149",
      "serviceCode":"PP_FIRSTISSUANCE",
      "documentTypeCode":"PP",
      "state":"CREATED",
      "contactStreetVillage":"BOBANG",
      "contactPhone":"9849004881",
      "citizenNum":"50206018769",
      "isExactDateOfBirth":"true",
      "pieces":[
        {"name":"Citizenship Certificate Front",
        "mimeType":"image/jpeg",
        "label":"Citizenship Certificate Front",
        "type":"Citizenship Certificate",
        "value":"d4b9d501cad3f0e8e7d7331f5a83f1da58daa7a6ed879168bdaeba08a589795a"},
        {"name":"Citizenship Certificate Back",
        "mimeType":"image/jpeg",
        "label":"Citizenship Certificate Back",
        "type":"Citizenship Certificate",
        "value":"29012c81352e28fcabaa12ced1ea9f7cef3aa1e5d469cdf242b3b6aea5fe073a"},
        {"name":"National eID",
        "mimeType":"image/jpeg",
        "label":"National eID",
        "type":"National eID",
        "value":"85e193d20415c0161ea95f9d50ec8e4c1099749457dd47bd96efccd450f21438"}],
      "appointment": {},
      "enrollementCenterCode": @enrollment_center_code
    }
  end
end



dm = DateMaker.new
# dm.get_time_slots
appt_id = dm.get_appointment
# appt_id = dm.get_followup("43dbbb7c-8f22-4cc0-84c3-b879979b786f","2000-02-22")
dm.submit_form
