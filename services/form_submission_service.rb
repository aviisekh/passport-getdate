#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative '../lib/passport_api_service'
require_relative '../lib/captcha_handler'
require_relative 'file_upload_service'
require 'json'

# Simple service for submitting passport application forms
# Handles form submission after appointment is booked
class FormSubmissionService
  def initialize(api_service:, config:)
    @api_service = api_service
    @config = config
    @file_upload_service = FileUploadService.new(api_service: api_service, config: config)
    @captcha_handler = CaptchaHandler.new(api_service)
  end

  # Submit the complete form with appointment data
  # @param appointment_data [Hash] The appointment data returned from booking
  # @return [Hash] The submission result
  def submit_form(appointment_data)
    log("Preparing form submission...")
    # Upload files if needed (only once, reuse for all attempts)
    file_pieces = @file_upload_service.upload_required_files
    
    # Prepare form data
    form_data = build_form_data
    form_data = form_data.merge(pieces: file_pieces)
    form_data = form_data.merge(appointment: appointment_data)

    
    # Get location token (this might be from a previous step or session)
    location_token = @config[:location_token] || generate_location_token
    
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

  def build_form_data
    # Merge with user config data
    base_form_data = @config[:form_data] || {}
    base_form_data.merge(
      "enrollementCenterCode" => @config[:enrollment_center_code] || "DOP"
    )
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

