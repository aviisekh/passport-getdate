#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative '../lib/passport_api_service'
require_relative '../lib/captcha_handler'
require 'json'

# Simple service for submitting passport application forms
# Handles file uploads and form submission after appointment is booked
class FormSubmissionService
  def initialize(api_service:, config:)
    @api_service = api_service
    @config = config
    @file_references = nil # Cache file uploads
    @captcha_handler = CaptchaHandler.new(api_service)
  end

  # Submit the complete form with appointment data
  # @param appointment_data [Hash] The appointment data returned from booking
  # @return [Hash] The submission result
  def submit_form(appointment_data)
    log("Preparing form submission...")
    # Upload files if needed (only once, reuse for all attempts)
    # @file_references ||= upload_required_files
    
    # Prepare form data
    # form_data = build_form_data(@file_references)

    base_form_data = @config[:form_data] || {}
    pieces = [{"name":"Citizenship Certificate Front","mimeType":"image/jpeg","label":"Citizenship Certificate Front","type":"Citizenship Certificate","value":"bea6b1bc4cbbfa69d720b1c351655de73c95d86cd126a243dd6d57f8e8d14c65"},{"name":"Citizenship Certificate Back","mimeType":"image/jpeg","label":"Citizenship Certificate Back","type":"Citizenship Certificate","value":"0c47520efe27fa5d1f11a80aef50e60f6095994539782f09db18502e587d6cb1"}]
    base_form_data.merge!(
      "pieces" => pieces,
      "enrollementCenterCode" => @config[:enrollment_center_code] || "DOP"
    )
    # form_data = base_form_data.merge(appointment_data)
    form_data = {"version":"0","preEnrollApplId":"","documentTypeOthers":"test","lastName":"BHATTA","firstName":"ABHISHEK","birthCountry":"NPL","dateOfBirth":"1994-09-24","dateOfBirthBS":"2051-06-08","birthDistrict":"KNP","citizenIssuePlaceDistrict":"KNP","contactLastName":"BHATTA","contactFirstName":"KESHAB","mainAddressCountry":"NPL","citizenIssueDateBS":"2068-06-28","gender":"M","nationality":"NPL","fatherLastName":"BHATTA","fatherFirstName":"KESHAB","motherLastName":"BHATTA","motherFirstName":"KHAGESHWORI","homePhone":"+977 9843288950","email":"aviisekh@gmail.com","contactMunicipality":"LTP-MLX00A","contactCountry":"NPL","contactDistrict":"LTP","mainAddressWard":"05","contactWard":"05","mainAddressMunicipality":"LTP-MLX00A","mainAddressDistrict":"LTP","mainAddressProvince":"BGM","contactProvince":"BGM","mainAddressStreetVillage":"TIKATHALI","nin":"7667514666","serviceCode":"PP_RENEWAL","documentTypeCode":"PP","state":"CREATED","contactStreetVillage":"TIKATHALI","contactPhone":"9848726300","currentTDNum":"09409094","currentTDIssueDate":"2015-12-18","currenttdIssuePlaceDistrict":"KNP","citizenNum":"75100113562","isExactDateOfBirth":"true",
    "pieces":[{"name":"Citizenship Certificate Front","mimeType":"image/jpeg","label":"Citizenship Certificate Front","type":"Citizenship Certificate","value":"bea6b1bc4cbbfa69d720b1c351655de73c95d86cd126a243dd6d57f8e8d14c65"},{"name":"Citizenship Certificate Back","mimeType":"image/jpeg","label":"Citizenship Certificate Back","type":"Citizenship Certificate","value":"0c47520efe27fa5d1f11a80aef50e60f6095994539782f09db18502e587d6cb1"}],
    "enrollementCenterCode":"DOP",
    "appointment":{"id":10601649,"appointmentDate":"2025-11-16T00:00:00.000Z","timeSlot":"11:30","locationId":79,"isVip":false}}

    # Get location token (this might be from a previous step or session)
    # location_token = @config[:location_token] || generate_location_token
    location_token = "1a73dff26b66f5dd67403e250379bd80"
    
    # Try to submit form, handling captcha if needed
    max_captcha_attempts = 3
    captcha_attempts = 0
    
    begin
      captcha_id = nil
      captcha_text = nil
      
      # Get captcha if handler is available
      if @captcha_handler
        captcha_data = @captcha_handler.get_captcha
        captcha_info = @captcha_handler.solve_captcha_manually(captcha_data)
        captcha_id = captcha_info[:captcha_id]
        captcha_text = captcha_info[:captcha_text]
        log("Using captcha ID: #{captcha_id}, captcha text: #{captcha_text}")
      end
      
      # Submit form with captcha
      log("Submitting form...")
      result = @api_service.submit_form(
        form_data, 
        appointment_data, 
        location_token,
        captcha_id: captcha_id,
        captcha_text: captcha_text
      )
      log("Form submitted successfully: #{result.inspect}")
      
      result
      
    rescue => e
      # Check if it's a captcha error
      if e.message.include?("captcha") || e.message.include?("CAPTCHA") || e.message.include?("Wrong captcha")
        captcha_attempts += 1
        
        if captcha_attempts < max_captcha_attempts && @captcha_handler
          log("Captcha error detected during form submission. Retrying with new captcha (attempt #{captcha_attempts + 1}/#{max_captcha_attempts})...")
          
          # Get new captcha and retry
          captcha_data = @captcha_handler.get_captcha
          captcha_info = @captcha_handler.solve_captcha_manually(captcha_data)
          captcha_id = captcha_info[:captcha_id]
          captcha_text = captcha_info[:captcha_text]
          log("Using new captcha ID: #{captcha_id}, captcha text: #{captcha_text}")
          
          # Retry with new captcha
          retry
        else
          log("Max captcha attempts reached or no captcha handler available")
          raise "Captcha verification failed after #{captcha_attempts} attempts: #{e.message}"
        end
      else
        # Not a captcha error, re-raise
        log("Error: #{e.message}")
        raise e
      end
    end
  end

  private

  def upload_required_files
    log("Uploading required files...")
    file_references = {}
    
    # Upload citizenship front
    if @config[:citizenship_front_path]
      front_meta = {
        "name" => "Citizenship Certificate Front",
        "mimeType" => "image/jpeg",
        "label" => "Citizenship Certificate Front",
        "type" => "Citizenship Certificate"
      }
      file_references[:front] = @api_service.upload_file(
        @config[:citizenship_front_path],
        front_meta
      )
      log("Front uploaded: #{file_references[:front]}")
    end
    
    # Upload citizenship back
    if @config[:citizenship_back_path]
      back_meta = {
        "name" => "Citizenship Certificate Back",
        "mimeType" => "image/jpeg",
        "label" => "Citizenship Certificate Back",
        "type" => "Citizenship Certificate"
      }
      file_references[:back] = @api_service.upload_file(
        @config[:citizenship_back_path],
        back_meta
      )
      log("Back uploaded: #{file_references[:back]}")
    end
    
    # Upload national ID if provided
    if @config[:national_id_path]
      id_meta = {
        "name" => "National eID",
        "mimeType" => "image/jpeg",
        "label" => "National eID",
        "type" => "National eID"
      }
      file_references[:national_id] = @api_service.upload_file(
        @config[:national_id_path],
        id_meta
      )
      log("National ID uploaded: #{file_references[:national_id]}")
    end
    
    file_references
  end

  def build_form_data(file_references)
    pieces = []
    
    # File upload API returns JSON with 'value' field containing the hash
    if file_references[:front]
      value = extract_file_value(file_references[:front])
      pieces << {
        "name" => "Citizenship Certificate Front",
        "mimeType" => "image/jpeg",
        "label" => "Citizenship Certificate Front",
        "type" => "Citizenship Certificate",
        "value" => value
      } if value
    end
    
    if file_references[:back]
      value = extract_file_value(file_references[:back])
      pieces << {
        "name" => "Citizenship Certificate Back",
        "mimeType" => "image/jpeg",
        "label" => "Citizenship Certificate Back",
        "type" => "Citizenship Certificate",
        "value" => value
      } if value
    end
    
    if file_references[:national_id]
      value = extract_file_value(file_references[:national_id])
      pieces << {
        "name" => "National eID",
        "mimeType" => "image/jpeg",
        "label" => "National eID",
        "type" => "National eID",
        "value" => value
      } if value
    end
    
    # Merge with user config data
    base_form_data = @config[:form_data] || {}
    base_form_data.merge(
      "pieces" => pieces,
      "enrollementCenterCode" => @config[:enrollment_center_code] || "DOP"
    )
  end

  def extract_file_value(file_response)
    # API response can be a hash with 'value' key, or the value might be in the response body
    if file_response.is_a?(Hash)
      file_response['reference'] || file_response[:reference] || file_response.to_s
    else
      # If response is a string, try to parse as JSON
      begin
        parsed = JSON.parse(file_response)
        parsed['reference'] || file_response.to_s
      rescue
        file_response.to_s
      end
    end
  end

  def generate_location_token
    # This might need to be obtained from a session or previous API call
    # For now, using a placeholder - you may need to implement session management
    @config[:location_token] || "c96878d9dc2740e89e11c7727c73367d"
  end

  def log(message)
    puts "[#{Time.now.strftime('%Y-%m-%d %H:%M:%S')}] #{message}"
  end
end

