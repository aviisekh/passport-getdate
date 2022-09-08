#!/Users/aviisekh/.rbenv/shims/ruby
require 'net/http'
require 'uri'
require 'json'

body = {"version":"0",
  "preEnrollApplId":"",
  "documentTypeOthers":"test",
  "lastName":"BHATTA",
  "firstName":"ABHISHEK",
  "birthCountry":"NPL",
  "dateOfBirth":"2022-09-01",
  "dateOfBirthBS":"2011-11-11",
  "birthDistrict":"ACM",
  "citizenIssuePlaceDistrict":"ACM",
  "contactLastName":"TTT",
  "contactFirstName":"TTT",
  "mainAddressCountry":"NPL",
  "citizenIssueDateBS":"2033-11-11",
  "gender":"M",
  "nationality":"NPL",
  "fatherLastName":"BHATTA",
  "fatherFirstName":"ABHISHEK",
  "motherLastName":"BHATTA",
  "motherFirstName":"ABHISHEK",
  "homePhone":"+977 9844288950",
  "email":"lol@gmail.com",
  "contactEmail":"TTT@gmail.com",
  "contactMunicipality":"BKT-BKT00A",
  "contactCountry":"NPL",
  "contactDistrict":"BKT",
  "mainAddressWard":"19",
  "contactWard":"18",
  "mainAddressMunicipality":"GOR-AGT00A",
  "mainAddressDistrict":"GOR",
  "mainAddressProvince":"GDK",
  "contactProvince":"BGM",
  "mainAddressStreetVillage":"BTT",
  "nin":"1234563432",
  "serviceCode":"PP_FIRSTISSUANCE",
  "documentTypeCode":"PP",
  "state":"CREATED",
  "contactStreetVillage":"TTT",
  "contactPhone":"9844444345",
  "citizenNum":"12321432543",
  "isExactDateOfBirth":"true",
  "pieces":[
    {
      "name":"Citizenship Certificate Front",
      "mimeType":"image/png",
      "label":"Citizenship Certificate Front",
      "type":"Citizenship Certificate",
      "value":"1ac8518f8f487d7ee7d1b793b597052d02a6702c7ab1ec31d093c6c56cea2c89"
    },
      {
        "name":"Citizenship Certificate Back",
        "mimeType":"image/png",
        "label":"Citizenship Certificate Back",
        "type":"Citizenship Certificate",
        "value":"c51b955ad195ab6f50bb00fa8772b3a09260d783852cd298e937c6ba7f2d8f0f"
        }
      ],
  "appointment":{
    "id": "null",
    "appointmentDate":"2022-09-08T13:01:49.656Z",
    "timeSlot":"11:00",
    "locationId":21,
    "isVip":false
  },
    "enrollementCenterCode":"DIH"
  }

 body = {
    "version":"0",
    "preEnrollApplId":"",
    "documentTypeOthers":"test",
    "lastName":"PANT",
    "firstName":"BIMALA",
    "birthCountry":"NPL",
    "dateOfBirth":"2000-06-11",
    "dateOfBirthBS":"2057-02-29",
    "birthDistrict":"KNP",
    "citizenIssuePlaceDistrict":"KNP",
    "contactLastName":"PANT",
    "contactFirstName":"POOJA",
    "mainAddressCountry":"NPL",
    "citizenIssueDateBS":"2073-07-08",
    "gender":"F",
    "nationality":"NPL",
    "fatherLastName":"PANT",
    "fatherFirstName":"DIPENDRA",
    "motherLastName":"PANT",
    "motherFirstName":"TARA",
    "homePhone":"+977 9843082984",
    "email":"pantbimala057@gmail.com",
    "contactMunicipality":"KNP-BDT00A",
    "contactCountry":"NPL",
    "contactDistrict":"KNP",
    "mainAddressWard":"16",
    "contactWard":"16",
    "mainAddressMunicipality":"KNP-BDT00A",
    "mainAddressDistrict":"KNP",
    "mainAddressProvince":"SDP",
    "contactProvince":"SDP",
    "mainAddressStreetVillage":"MAJGAON",
    "nin":"5837711490",
    "serviceCode":"PP_FIRSTISSUANCE",
    "documentTypeCode":"PP",
    "state":"CREATED",
    "contactStreetVillage":"MAJGAON",
    "contactPhone":"9861112248",
    "citizenNum":"75017305469",
    "isExactDateOfBirth":"true",
    "pieces":[
      {"name":"Citizenship Certificate Front",
      "mimeType":"image/jpeg",
      "label":"Citizenship Certificate Front",
      "type":"Citizenship Certificate",
      "value":"ff207eb43e2325f8a1ec629615b9226226f4f08119762a0c5d5e2707bae8c217"},
      {"name":"Citizenship Certificate Back",
      "mimeType":"image/jpeg",
      "label":"Citizenship Certificate Back",
      "type":"Citizenship Certificate",
      "value":"c6c3ca546e6a1a63cb9440cdcd39258e986a82455c4a47ce6efa73c343c12fbf"},
      {"name":"National eID",
      "mimeType":"image/jpeg",
      "label":"National eID",
      "type":"National eID",
      "value":"e2f0555ab0e237ca57f10fb301ad4abca51ecb789634f91fbe0da119a8a61789"}
  ],
  "appointment":{
    "id": "null",
    "appointmentDate":"2022-09-12T15:33:09.520Z",
    "timeSlot":"14:00",
    "locationId":79,
    "isVip":false
  },
  "enrollementCenterCode":"DOP"
}
  
uri = URI.parse("https://emrtds.nepalpassport.gov.np/iups-api/eservices/perform/")

http = Net::HTTP.new(uri.host, uri.port)
http.use_ssl = true
http.verify_mode = OpenSSL::SSL::VERIFY_PEER

request = Net::HTTP::Post.new(uri.request_uri)
request.content_type = "application/json"
request["location"] = "3ff2b8fafe3bd73b627e8f295ea34f31"
request.body = JSON.dump(body) 

response = http.request(request)

puts response.body



# curl 'https://emrtds.nepalpassport.gov.np/iups-api/eservices/perform/' \
#   -H 'Content-Type: application/json' \
#   -H 'Origin: https://emrtds.nepalpassport.gov.np' \
#   -H 'location: d08a6886271a2606ccc69f4cef0be9f3' \
#   --data-raw '{"version":"0","preEnrollApplId":"","documentTypeOthers":"test","lastName":"BHATTA","firstName":"ABHISHEK","birthCountry":"NPL","dateOfBirth":"2022-09-01","dateOfBirthBS":"2011-11-11","birthDistrict":"ACM","citizenIssuePlaceDistrict":"ACM","contactLastName":"TTT","contactFirstName":"TTT","mainAddressCountry":"NPL","citizenIssueDateBS":"2033-11-11","gender":"M","nationality":"NPL","fatherLastName":"BHATTA","fatherFirstName":"ABHISHEK","motherLastName":"BHATTA","motherFirstName":"ABHISHEK","homePhone":"+977 9844288950","email":"lol@gmail.com","contactEmail":"TTT@gmail.com","contactMunicipality":"BKT-BKT00A","contactCountry":"NPL","contactDistrict":"BKT","mainAddressWard":"19","contactWard":"18","mainAddressMunicipality":"GOR-AGT00A","mainAddressDistrict":"GOR","mainAddressProvince":"GDK","contactProvince":"BGM","mainAddressStreetVillage":"BTT","nin":"1234563432","serviceCode":"PP_FIRSTISSUANCE","documentTypeCode":"PP","state":"CREATED","contactStreetVillage":"TTT","contactPhone":"9844444345","citizenNum":"12321432543","isExactDateOfBirth":"true","pieces":[{"name":"Citizenship Certificate Front","mimeType":"image/png","label":"Citizenship Certificate Front","type":"Citizenship Certificate","value":"1ac8518f8f487d7ee7d1b793b597052d02a6702c7ab1ec31d093c6c56cea2c89"},{"name":"Citizenship Certificate Back","mimeType":"image/png","label":"Citizenship Certificate Back","type":"Citizenship Certificate","value":"c51b955ad195ab6f50bb00fa8772b3a09260d783852cd298e937c6ba7f2d8f0f"}],"appointment":{"id":"null","appointmentDate":"2022-09-07T13:01:49.656Z","timeSlot":"11:30","locationId":21,"isVip":false},"enrollementCenterCode":"DIH"}' \
#   --compressed