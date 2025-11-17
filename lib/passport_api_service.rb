#!/usr/bin/env ruby
# frozen_string_literal: true

require 'net/http'
require 'uri'
require 'json'
require 'date'
require 'pry-rails'

# Service class for interacting with Nepal Passport API
class PassportApiService
  BASE_URL = 'https://emrtds.nepalpassport.gov.np/iups-api'

  def initialize(retry_delay: 0.1, max_retries: 10)
    @retry_delay = retry_delay
    @max_retries = max_retries # Reduced retries for faster failure and retry
  end

  # Get calendar for a location
  def get_calendar(location_id)
    uri = URI.parse("#{BASE_URL}/calendars/#{location_id}/false")
    response = make_request(:get, uri)
    JSON.parse(response.body)
  end

  # Get available time slots for a location and date
  def get_time_slots(location_id, date)
    uri = URI.parse("#{BASE_URL}/timeslots/#{location_id}/#{date}/false")
    response = make_request(:get, uri)
    JSON.parse(response.body)
  end

  # Get captcha challenge
  # Note: The actual endpoint may vary. Common endpoints: /captcha, /captcha/challenge, /appointments/captcha
  def get_captcha_challenge
    # Try common captcha endpoints
    captcha_endpoint = "#{BASE_URL}/captcha"
    last_error = nil
    begin
      uri = URI.parse(captcha_endpoint)
      response = make_request(:get, uri)
      result = JSON.parse(response.body)
      log("Captcha fetched from: #{captcha_endpoint}")
      return result
    rescue => e
      last_error = e
    end
  end

  # Create an appointment with captcha
  # @param appointment_data [Hash] The appointment data
  # @param captcha_id [String] The captcha ID from refresh endpoint
  # @param captcha_text [String] The captcha text entered by user
  def create_appointment(appointment_data, captcha_id: nil, captcha_text: nil)
    uri = URI.parse("#{BASE_URL}/appointments")
    
    # Prepare request with captcha headers if provided
    request = create_request(:post, uri, appointment_data, nil)
    
    # Add captcha information as headers (not in body)
    if captcha_id && captcha_text
      request["Captchaid"] = captcha_id
      request["Captchatext"] = captcha_text
      log("Adding captcha headers: Captchaid=#{captcha_id}, Captchatext=#{captcha_text}")
    end
    
    response = make_request_with_headers(:post, uri, appointment_data, request)
    appointment_id = JSON.parse(response.body)
    appointment_data.merge("id" => appointment_id)
  end

  # Upload a file
  def upload_file(file_path, document_metadata)
    require 'net/http/post/multipart'
    
    uri = URI.parse("#{BASE_URL}/scan")
    
    retries = 0
    while retries < @max_retries
      begin
        http = create_http_client(uri)
        
        File.open(file_path) do |file|
          req = Net::HTTP::Post::Multipart.new(
            uri.path,
            file: UploadIO.new(file, "image/jpeg", File.basename(file_path)),
            document: JSON.dump(document_metadata)
          )
          # Add browser-like headers to file upload requests too
          add_browser_headers(req)
          response = http.request(req)
          
          if response.code == "200"
            # API returns JSON with file reference
            result = JSON.parse(response.body)
            return result
          else
            raise "File upload failed: HTTP #{response.code} - #{response.body}"
          end
        end
      rescue Errno::ECONNRESET, Errno::EPIPE, Errno::ETIMEDOUT, 
             OpenSSL::SSL::SSLError, Net::OpenTimeout, Net::ReadTimeout, 
             Net::WriteTimeout, EOFError => e
        if retries < @max_retries - 1
          delay = @retry_delay * (2 ** retries)
          log("File upload connection error (#{e.class}): #{e.message}. Retrying in #{delay}s...")
          sleep(delay)
        else
          log("Max retries reached for file upload. Last error: #{e.class}: #{e.message}")
          raise e
        end
      rescue => e
        if retries < @max_retries - 1
          delay = @retry_delay * (2 ** retries)
          log("File upload error (#{e.class}): #{e.message}. Retrying in #{delay}s...")
          sleep(delay)
        else
          raise e
        end
      end
      
      retries += 1
    end
    
    raise "Max retries reached for file upload."
  end

  # Submit the passport application form
  # @param form_data [Hash] The form data to submit
  # @param appointment_data [Hash] The appointment data
  # @param location_token [String] The location token
  # @param captcha_id [String] The captcha ID from refresh endpoint
  # @param captcha_text [String] The captcha text entered by user
  def submit_form(form_data, appointment_data, location_token, captcha_id: nil, captcha_text: nil)
    uri = URI.parse("#{BASE_URL}/eservices/perform/")
    body = form_data.merge(appointment: appointment_data)
   
    # Prepare request with captcha headers if provided
    request = create_request(:post, uri, body, location_token)
    
    # Add captcha information as headers (not in body)
    if captcha_id && captcha_text
      request["Captchaid"] = captcha_id
      request["Captchatext"] = captcha_text
      log("Adding captcha headers to form submission: Captchaid=#{captcha_id}, Captchatext=#{captcha_text}")
    end
    
    binding.pry

    response = make_request_with_headers(:post, uri, body, request)
    JSON.parse(response.body)
    puts "Response: #{response.body}"
  end

  # Create a follow-up entry for the submitted form
  # @param request_number [String] The request number from form submission
  # @param birth_date [String] The birth date (format: YYYY-MM-DD)
  # @return [Array] The follow-up response containing request details
  def create_followup(request_number, birth_date)
    uri = URI.parse("#{BASE_URL}/eservices/followup/")
    body = {
      "requestNumber" => request_number,
      "birthDate" => birth_date
    }
    
    request = create_request(:post, uri, body, nil)
    response = make_request_with_headers(:post, uri, body, request)
    JSON.parse(response.body)
  end

  private

  def make_request(method, uri, body = nil, location_token = nil)
    request = create_request(method, uri, body, location_token)
    make_request_with_headers(method, uri, body, request)
  end

  def make_request_with_headers(method, uri, body, request)
    retries = 0
    while retries < @max_retries
      begin
        # Create a fresh HTTP client for each request to avoid connection reuse issues
        http = create_http_client(uri)
        binding.pry
        response = http.request(request)
        
        if response.code == "200"
          return response
        elsif response.code == "429" # Rate limited
          # Wait a bit longer for rate limits
          sleep(@retry_delay * (2 ** retries))
        elsif response.code == "400"
          # Check if it's a captcha error
          error_body = response.body
          if error_body.include?("captcha") || error_body.include?("CAPTCHA") || error_body.include?("Wrong captcha")
            # This is a captcha error - don't retry automatically, let the caller handle it
            raise "HTTP #{response.code}: #{error_body}"
          else
            # Other 400 errors - fail fast
            raise "HTTP #{response.code}: #{error_body}"
          end
        else
          # For other errors, fail fast and let caller retry
          raise "HTTP #{response.code}: #{response.body}"
        end
      rescue Errno::ECONNRESET, Errno::EPIPE, Errno::ETIMEDOUT, 
             OpenSSL::SSL::SSLError, Net::OpenTimeout, Net::ReadTimeout, 
             Net::WriteTimeout, EOFError => e
        # Connection-related errors - retry with exponential backoff
        if retries < @max_retries - 1
          delay = @retry_delay * (2 ** retries)
          log("Connection error (#{e.class}): #{e.message}. Retrying in #{delay}s...")
          sleep(delay)
        else
          log("Max retries reached. Last error: #{e.class}: #{e.message}")
          raise e
        end
      rescue => e
        # Other errors
        if retries < @max_retries - 1
          delay = @retry_delay * (2 ** retries)
          log("Error (#{e.class}): #{e.message}. Retrying in #{delay}s...")
          sleep(delay)
        else
          log("Max retries reached. Last error: #{e.class}: #{e.message}")
          raise e
        end
      end
      
      retries += 1
    end
    
    raise "Max retries reached. Failed to get successful response."
  end

  def create_http_client(uri)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.verify_mode = OpenSSL::SSL::VERIFY_PEER
    
    # Set timeouts to prevent hanging connections
    http.open_timeout = 10  # Connection timeout
    http.read_timeout = 30  # Read timeout
    http.write_timeout = 30 # Write timeout
    
    # Keep-alive settings
    http.keep_alive_timeout = 5
    
    # SSL/TLS settings - let Ruby negotiate the best version
    # Some servers are picky about SSL version, so we'll let it auto-negotiate
    # http.ssl_version = :TLSv1_2  # Commented out to allow auto-negotiation
    
    http
  end

  def create_request(method, uri, body, location_token)
    case method
    when :get
      request = Net::HTTP::Get.new(uri.request_uri)
    when :post
      request = Net::HTTP::Post.new(uri.request_uri)
      request.content_type = "application/json"
      request.body = JSON.dump(body) if body
      request["location"] = location_token if location_token
    else
      raise "Unsupported HTTP method: #{method}"
    end
    
    # Add browser-like headers to avoid being blocked
    add_browser_headers(request)
    request
  end
  
  def add_browser_headers(request)
    # User-Agent is critical - servers often block requests without it
    request["User-Agent"] = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"
    request["Accept"] = "application/json, text/plain, */*"
    request["Accept-Language"] = "en-US,en;q=0.9"
    # Note: Not including Accept-Encoding since Ruby's Net::HTTP doesn't auto-decompress
    request["Connection"] = "keep-alive"
    request["Referer"] = "https://emrtds.nepalpassport.gov.np/"
    request["Origin"] = "https://emrtds.nepalpassport.gov.np"
  end

  def log(message)
    puts "[#{Time.now.strftime('%Y-%m-%d %H:%M:%S')}] #{message}"
  end
end

