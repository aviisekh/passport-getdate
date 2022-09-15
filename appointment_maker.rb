#!/Users/aviisekh/.rbenv/shims/ruby
require 'net/http'
require 'uri'
require 'json'
require 'pry-rails'

uri = URI.parse("https://emrtds.nepalpassport.gov.np/iups-api/eservices/followup/")
body = {"id":null,
  "appointmentDate":"2022-09-15T15:07:06.899Z",
  "timeSlot":"11:00",
  "locationId":21,
  "isVip":false}
  
http = Net::HTTP.new(uri.host, uri.port)
http.use_ssl = true
http.verify_mode = OpenSSL::SSL::VERIFY_PEER

request = Net::HTTP::Post.new(uri.request_uri)
request.content_type = "application/json"
request.body = JSON.dump(body)

response = nil;
while true do 
  sleep(1)
  begin 
    response = http.request(request)
    break if response.code == "200"

  rescue
    p "Failed, Trying again..."
  end
end
# response = http.request(request)
# binding.pry
puts response.body

# Curl Syntax
# curl 'https://emrtds.nepalpassport.gov.np/iups-api/eservices/followup/' \
#   -H 'Content-Type: application/json' \
#   -H 'Origin: https://emrtds.nepalpassport.gov.np' \
#   --data '{"requestNumber":"b1a4db2b-0375-4679-a891-063a15fec6f5","birthDate":"2022-09-01"}' \
#   --compressed


