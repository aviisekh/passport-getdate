#!/Users/aviisekh/.rbenv/shims/ruby
require 'net/http'
require 'uri'
require 'json'
require 'net/http/post/multipart'

front_file_document = {
  "name":"Citizenship Certificate Front",
  "mimeType":"image/png",
  "label":"Citizenship Certificate Front",
  "type":"Citizenship Certificate"
}
front_file_path = "/Users/aviisekh/Development/passport-getdate/front.jpeg"

back_file_document = {
  "name":"Citizenship Certificate Back",
  "mimeType":"image/png",
  "label":"Citizenship Certificate Back",
  "type":"Citizenship Certificate"
}
back_file_path = "/Users/aviisekh/Development/passport-getdate/back.jpeg"


uri = URI.parse('https://emrtds.nepalpassport.gov.np/iups-api/scan')

http = Net::HTTP.new(uri.host, uri.port)
http.use_ssl = true
http.verify_mode = OpenSSL::SSL::VERIFY_PEER

front_reference= File.open(front_file_path) do |jpg|
  req = Net::HTTP::Post::Multipart.new uri.path, file: UploadIO.new(jpg, "image/jpeg", "image.jpg"), document: JSON.dump(front_file_document)
  response = http.request(req)
  {front: response.body}
end

back_reference= File.open(back_file_path) do |jpg|
  req = Net::HTTP::Post::Multipart.new uri.path, file: UploadIO.new(jpg, "image/jpeg", "image.jpg"), document: JSON.dump(back_file_document)
  response = http.request(req)
  {back: response.body}
end

print [front_reference, back_reference]



# Add Front ======================================================
# curl 'https://emrtds.nepalpassport.gov.np/iups-api/scan' \
#   -X 'POST' \
#   # --compressed

# Delete File
# curl 'https://emrtds.nepalpassport.gov.np/iups-api/I5/media/dea399d598631cd922f3139a88c36c10c04b7831ec38c9646f7d197d96a64022' \
#   -X 'DELETE' \
#   --compressed