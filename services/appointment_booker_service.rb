#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative '../lib/passport_api_service'
require_relative '../lib/captcha_handler'

require 'date'
require 'time'

# Base class for appointment booking services
# Handles the core logic of finding and booking appointment slots
class AppointmentBookerService
  TARGET_TIME_RANGE = (9..18) # 9am to 6pm
  DEFAULT_POLL_INTERVAL = 1 # Polling interval in seconds
  DEFAULT_MAX_DURATION = 3600 # 1 hour max

  def initialize(api_service:, location_id:, target_date:, poll_interval: DEFAULT_POLL_INTERVAL, max_duration: DEFAULT_MAX_DURATION)
    @api_service = api_service
    @location_id = location_id
    @target_date = target_date
    @poll_interval = poll_interval
    @max_duration = max_duration
    @booking_successful = false
    @captcha_handler = CaptchaHandler.new(api_service)
  end   

  # Main method to book an appointment
  # Returns appointment data hash on success, nil on failure
  # Book an appointment using sequential polling
  # Returns appointment data hash on success, nil on failure
  def book
    log("\n\nStarting simple sequential polling for available time slots...")
    
    # First, do a quick calendar check to verify date is available
    verify_date_available
    
    log("Date verified. Starting continuous time slot polling...")
    log("Polling every #{@poll_interval} seconds (simple sequential mode)\n\n")
    
    attempt = 0
    start_time = Time.now
    
    # Simple continuous polling loop - sequential requests
    while (Time.now - start_time) < @max_duration && !@booking_successful
      attempt += 1
      
      begin
        # Poll time slots - simple sequential request
        time_slots = @api_service.get_time_slots(@location_id, @target_date.to_s)
        
        # Find available slots in target time range (9am-6pm)
        available_slots = find_all_available_slots(time_slots)
        
        if available_slots.any?
          slot_details = available_slots.map { |s| "#{s['name'] || s[:name]} (capacity: #{s['capacity'] || s[:capacity]})" }.join(", ")
          log("🎯 SLOTS FOUND! Attempt #{attempt}: #{available_slots.length} slot(s) available - #{slot_details}")
          
          # Try to book the first available slot
          slot_to_book = available_slots.first
          log("Attempting to book slot: #{slot_to_book['name'] || slot_to_book[:name]}")
          
          begin
            appointment_data = create_appointment_for_slot(slot_to_book, captcha_handler: @captcha_handler)
            @booking_successful = true
            log("✅ Successfully booked appointment!")
            return appointment_data
          rescue => e
            log("❌ Failed to book slot: #{e.message}")
            log("\n\nContinuing to poll...")
          end
        end
        
      rescue => e
        # Log errors occasionally to avoid spam
        if attempt % 100 == 0
          log("Error (attempt #{attempt}): #{e.message}")
        end
      end
      
      # Wait before next poll attempt
      sleep(@poll_interval) if @poll_interval > 0
      
      # Log progress every 100 attempts
      if attempt % 100 == 0
        elapsed = Time.now - start_time
        log("Still polling... Attempt #{attempt}, Elapsed: #{elapsed.to_i}s")
      end
    end
    
    if !@booking_successful
      log("Max duration reached. Could not book appointment.")
      raise "Failed to book appointment after #{@max_duration} seconds of continuous polling"
    end
    
    nil
  end

  protected

  def verify_date_available
    log("Verifying target date is available...")
    
    begin
      calendar = @api_service.get_calendar(@location_id)
      
      min_date = Date.parse(calendar['minDate'])
      max_date = Date.parse(calendar['maxDate'])
      
      if @target_date < min_date || @target_date > max_date
        raise "Target date #{@target_date} not yet available. Range: #{min_date} to #{max_date}"
      end
      
      off_dates = calendar['offDates'] || []
      if off_dates.include?(@target_date.to_s)
        raise "Target date #{@target_date} is in off dates"
      end
      
      log("✓ Date #{@target_date} is available for booking")
    rescue => e
      log("⚠️  Date verification issue: #{e.message}")
      log("Will continue polling anyway - slots may become available...")
    end
  end

  def find_all_available_slots(time_slots)
    # API returns an array of slot hashes with: name, status, capacity, vipCapacity
    # Example: [{"name"=>"10:00", "status"=>true, "capacity"=>16, "vipCapacity"=>0}, ...]
    slots = time_slots.is_a?(Array) ? time_slots : []
    
    available = slots.select do |slot|
      # Only select slots that are available (status: true) and within target time range
      next false unless slot.is_a?(Hash)
      next false unless slot['status'] == true || slot[:status] == true
      
      slot_time = parse_slot_time(slot)
      if slot_time
        TARGET_TIME_RANGE.include?(slot_time.hour)
      else
        false
      end
    end
    
    available
  end

  def parse_slot_time(slot)
    # API response format: slot hash with 'name' field containing time like "10:00"
    time_str = if slot.is_a?(Hash)
      slot['name'] || slot[:name]
    else
      slot.to_s
    end
    
    return nil unless time_str && !time_str.empty?
    
    # Parse time string (format: "HH:MM" or "HH:MM:SS")
    parts = time_str.split(':')
    return nil if parts.length < 2
    
    hour = parts[0].to_i
    minute = parts[1].to_i
    
    Time.new(Time.now.year, Time.now.month, Time.now.day, hour, minute)
  rescue => e
    log("Error parsing slot time: #{e.message}")
    nil
  end

  def create_appointment_for_slot(slot, captcha_handler:)
    # Parse slot time from 'name' field (format: "10:00")
    time_slot = slot.is_a?(Hash) ? (slot['name'] || slot[:name]) : slot.to_s
    appointment_datetime = Time.parse("#{@target_date} #{time_slot}").utc.iso8601
    
    # Create appointment request
    appointment_request = {
      "id" => "null",
      "appointmentDate" => appointment_datetime,
      "timeSlot" => time_slot,
      "locationId" => @location_id,
      "isVip" => false
    }
    
    log("Creating appointment: #{appointment_request.inspect}")
    
    # Try to create appointment, handling captcha if needed
    max_captcha_attempts = 3
    captcha_attempts = 0
    
    begin
      captcha_id = nil
      captcha_text = nil
      
      # Get captcha if handler is provided
      if captcha_handler
        captcha_data = captcha_handler.get_captcha
        captcha_info = captcha_handler.solve_captcha_manually(captcha_data)
        captcha_id = captcha_info[:captcha_id]
        captcha_text = captcha_info[:captcha_text]
        log("Using captcha ID: #{captcha_id}, captcha text: #{captcha_text}")
      end
      
      # Create appointment with captcha
      appointment_data = @api_service.create_appointment(
        appointment_request, 
        captcha_id: captcha_id, 
        captcha_text: captcha_text
      )
      log("Appointment created: #{appointment_data.inspect}")
      
      appointment_data
      
    rescue => e
      # Check if it's a captcha error
      if e.message.include?("captcha") || e.message.include?("CAPTCHA") || e.message.include?("Wrong captcha")
        captcha_attempts += 1
        
        if captcha_attempts < max_captcha_attempts && captcha_handler
          log("Captcha error detected. Retrying with new captcha (attempt #{captcha_attempts + 1}/#{max_captcha_attempts})...")
          
          # Get new captcha and retry
          captcha_data = captcha_handler.get_captcha
          captcha_info = captcha_handler.solve_captcha_manually(captcha_data)
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
        raise e
      end
    end
  end

  def log(message)
    puts "[#{Time.now.strftime('%Y-%m-%d %H:%M:%S')}] #{message}"
  end
end

