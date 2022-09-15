#!/Users/aviisekh/.rbenv/shims/ruby
require 'net/http'
require 'uri'
require 'json'
require 'pry-rails'



 body = {"version":"0",
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
"appointment":{
  "id":"",
  "appointmentDate":"2022-09-21T14:38:08.544Z",
  "timeSlot":"11:00",
  "locationId":79,
  "isVip":false},
"enrollementCenterCode":"DOP"}
  
uri = URI.parse("https://emrtds.nepalpassport.gov.np/iups-api/eservices/perform/")

http = Net::HTTP.new(uri.host, uri.port)
http.use_ssl = true
http.verify_mode = OpenSSL::SSL::VERIFY_PEER

request = Net::HTTP::Post.new(uri.request_uri)
request.content_type = "application/json"
request["location"] = "c96878d9dc2740e89e11c7727c73367d"
request.body = JSON.dump(body) 

response = nil;
while true do 
  sleep(1)
  begin 
    response = http.request(request)
    if response.code.eql?"200"
      p "Success!!!"
      p response.body
      break 
    else
      p "New status code #{response.code}."
      p response.body
      p "Trying again..."
      # break
    end
  rescue
    p "Failed, Trying again..."
  end
end
# puts response.body

# curl 'https://emrtds.nepalpassport.gov.np/iups-api/eservices/perform/' \
#   -H 'Content-Type: application/json' \
#   -H 'Origin: https://emrtds.nepalpassport.gov.np' \
#   -H 'location: d08a6886271a2606ccc69f4cef0be9f3' \
#   --data-raw '{"version":"0","preEnrollApplId":"","documentTypeOthers":"test","lastName":"BHATTA","firstName":"ABHISHEK","birthCountry":"NPL","dateOfBirth":"2022-09-01","dateOfBirthBS":"2011-11-11","birthDistrict":"ACM","citizenIssuePlaceDistrict":"ACM","contactLastName":"TTT","contactFirstName":"TTT","mainAddressCountry":"NPL","citizenIssueDateBS":"2033-11-11","gender":"M","nationality":"NPL","fatherLastName":"BHATTA","fatherFirstName":"ABHISHEK","motherLastName":"BHATTA","motherFirstName":"ABHISHEK","homePhone":"+977 9844288950","email":"lol@gmail.com","contactEmail":"TTT@gmail.com","contactMunicipality":"BKT-BKT00A","contactCountry":"NPL","contactDistrict":"BKT","mainAddressWard":"19","contactWard":"18","mainAddressMunicipality":"GOR-AGT00A","mainAddressDistrict":"GOR","mainAddressProvince":"GDK","contactProvince":"BGM","mainAddressStreetVillage":"BTT","nin":"1234563432","serviceCode":"PP_FIRSTISSUANCE","documentTypeCode":"PP","state":"CREATED","contactStreetVillage":"TTT","contactPhone":"9844444345","citizenNum":"12321432543","isExactDateOfBirth":"true","pieces":[{"name":"Citizenship Certificate Front","mimeType":"image/png","label":"Citizenship Certificate Front","type":"Citizenship Certificate","value":"1ac8518f8f487d7ee7d1b793b597052d02a6702c7ab1ec31d093c6c56cea2c89"},{"name":"Citizenship Certificate Back","mimeType":"image/png","label":"Citizenship Certificate Back","type":"Citizenship Certificate","value":"c51b955ad195ab6f50bb00fa8772b3a09260d783852cd298e937c6ba7f2d8f0f"}],"appointment":{"id":"null","appointmentDate":"2022-09-07T13:01:49.656Z","timeSlot":"11:30","locationId":21,"isVip":false},"enrollementCenterCode":"DIH"}' \
#   --compressed