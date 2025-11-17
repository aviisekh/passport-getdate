#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative '../lib/passport_api_service'
require 'json'

# Service for creating follow-up entries after form submission
# Handles the follow-up API call and returns request details for printing
class FollowupService
  def initialize(api_service:, config:)
    @api_service = api_service
    @config = config
  end

  # Create a follow-up entry for the submitted form
  # @param submission_result [Hash] The result from form submission containing requestNumber
  # @return [Hash] Hash containing request_number, birth_date, and followup result
  def create_followup(submission_result)
    unless submission_result && submission_result["requestNumber"]
      log("Warning: Request number not found in submission result")
      return nil
    end

    request_number = submission_result["requestNumber"]
    
    # Get birth date from form data
    birth_date = extract_birth_date
    
    unless birth_date
      log("Warning: Birth date not found in form data, skipping follow-up")
      return nil
    end

    log("Creating follow-up entry...")
    log("Request Number: #{request_number}")
    log("Birth Date: #{birth_date}")
    
    begin
      followup_result = @api_service.create_followup(request_number, birth_date)
      log("Follow-up entry created successfully")
      
      {
        submission: submission_result,
        followup: followup_result,
        request_number: request_number,
        birth_date: birth_date
      }
    rescue => e
      log("Error creating follow-up entry: #{e.message}")
      raise e
    end
  end

  private

  def extract_birth_date
    # Try to get birth date from form_data in config
    @config[:form_data]&.dig("dateOfBirth") || 
    @config[:form_data]&.dig(:dateOfBirth) ||
    @config[:birth_date]
  end

  def log(message)
    puts "[#{Time.now.strftime('%Y-%m-%d %H:%M:%S')}] #{message}"
  end
end

