#!/Users/aviisekh/.rbenv/shims/ruby
require 'net/http'
require 'uri'
require 'json'

uri = URI.parse("https://emrtds.nepalpassport.gov.np/iups-api/eservices/followup/")
body = {
  "requestNumber":"b1a4db2b-0375-4679-a891-063a15fec6f5",
  "birthDate":"2022-09-01"
}

http = Net::HTTP.new(uri.host, uri.port)
http.use_ssl = true
http.verify_mode = OpenSSL::SSL::VERIFY_PEER

request = Net::HTTP::Post.new(uri.request_uri)
request.content_type = "application/json"
request.body = JSON.dump(body)

response = http.request(request)

puts response.body

# Curl Syntax
# curl 'https://emrtds.nepalpassport.gov.np/iups-api/eservices/followup/' \
#   -H 'Content-Type: application/json' \
#   -H 'Origin: https://emrtds.nepalpassport.gov.np' \
#   --data '{"requestNumber":"b1a4db2b-0375-4679-a891-063a15fec6f5","birthDate":"2022-09-01"}' \
#   --compressed


