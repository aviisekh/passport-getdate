#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative '../lib/passport_api_service'
require_relative 'appointment_booker_service'
require_relative 'form_submission_service'
require_relative 'followup_service'
require 'date'
require 'time'
require 'json'
require 'thread'

# Main automation class for booking passport appointments
# Orchestrates the appointment booking and form submission process
class AppointmentAutomator
  LOCATION_DOP = 79 # DOP (Tripureshwor) - from get_dates.rb
  DEFAULT_CONCURRENT_REQUESTS = 1 # Number of parallel requests to make
  DEFAULT_POLL_INTERVAL = 1 # Polling interval in seconds
  
  DEFAULT_RETRY_DELAY = 0.05 # Retry delay in seconds
  MAX_RETRIES = 1

  def initialize(config)
    @config = config
    @concurrent_requests = config[:concurrent_requests] || DEFAULT_CONCURRENT_REQUESTS
    @poll_interval = config[:poll_interval] || DEFAULT_POLL_INTERVAL
    
    # Create multiple API service instances with faster retry settings for concurrent requests
    @api_service = PassportApiService.new(retry_delay: DEFAULT_RETRY_DELAY, max_retries: MAX_RETRIES)
    @location_id = config[:location_id] || LOCATION_DOP
    @target_date = nil
  end 

  def run
    log("Starting appointment automation...")
    log("Target location: DOP (ID: #{@location_id})")
    log("Concurrent requests: #{@concurrent_requests}")
    log("Poll interval: #{@poll_interval} seconds")
    
    # Calculate target date (tomorrow)
    @target_date = Date.today + 1
    log("Target appointment date: #{@target_date}")
    
    # Wait until 5pm today
    # wait_until_booking_window
    
    # Step 1: Book appointment using appropriate booker
    appointment_data = {}#book_appointment
    
    # Step 2: Submit form with the booked appointment
    if appointment_data
      submission_result = submit_application_form(appointment_data)
      
      # Step 3: Create follow-up entry
      followup_result = create_followup_entry(submission_result)
      
      # Display request number and birth date for printing
      if followup_result && followup_result[:request_number] && followup_result[:birth_date]
        display_printing_details(followup_result)
      else
        log("✅ Appointment automation completed successfully!")
      end
    else
      raise "Failed to book appointment"
    end
  end

  private

  # Book appointment using sequential polling
  def book_appointment
    booker = AppointmentBookerService.new(
      api_service: @api_service,
      location_id: @location_id,
      target_date: @target_date,
      poll_interval: @poll_interval
    )
    
    booker.book
  end

  # Submit the application form after appointment is booked
  def submit_application_form(appointment_data)
    log("Submitting application form...")
    
    form_service = FormSubmissionService.new(
      api_service: @api_service,
      config: @config
    )
    
    form_service.submit_form(appointment_data)
  end

  # Create follow-up entry after form submission
  def create_followup_entry(submission_result)
    log("Creating follow-up entry...")
    
    followup_service = FollowupService.new(
      api_service: @api_service,
      config: @config
    )
    
    followup_service.create_followup(submission_result)
  end

  # Display the request number and birth date for printing
  def display_printing_details(followup_result)
    log("")
    log("=" * 60)
    log("✅ Appointment automation completed successfully!")
    log("=" * 60)
    log("")
    log("📋 IMPORTANT: Save these details to print your form:")
    log("   Request Number: #{followup_result[:request_number]}")
    log("   Birth Date: #{followup_result[:birth_date]}")
    log("")
    log("=" * 60)
  end

  def wait_until_booking_window
    now = Time.now
    target_time = Time.new(now.year, now.month, now.day, 17, 0, 0) # 5pm today
    
    if now < target_time
      wait_seconds = (target_time - now).to_i
      log("Waiting until 5pm (#{wait_seconds} seconds)...")
      sleep(wait_seconds)
    else
      log("Already past 5pm, proceeding immediately...")
    end
  end

  def log(message)
    puts "[#{Time.now.strftime('%Y-%m-%d %H:%M:%S')}] #{message}"
  end
end

