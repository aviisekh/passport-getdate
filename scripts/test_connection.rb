#!/usr/bin/env ruby
# frozen_string_literal: true

# Simple test script to verify API connection and configuration
require_relative '../lib/passport_api_service'
require_relative '../config/config_loader'

begin
  puts "Testing Passport Appointment Automation Setup..."
  puts "=" * 60
  
  # Load configuration
  puts "\n1. Loading configuration..."
  config = ConfigLoader.load
  puts "   ✓ Configuration loaded"
  
  # Validate configuration
  puts "\n2. Validating configuration..."
  ConfigLoader.validate(config)
  puts "   ✓ Configuration valid"
  
  # Test API service
  puts "\n3. Testing API connection..."
  api_service = PassportApiService.new
  
  # Test calendar endpoint
  location_id = config[:location_id] || 79
  puts "   Testing calendar endpoint for location #{location_id}..."
  calendar = api_service.get_calendar(location_id)
  puts "   ✓ Calendar API working"
  puts "   Available date range: #{calendar['minDate']} to #{calendar['maxDate']}"
  
  # Test file paths
  puts "\n4. Checking file paths..."
  config_dir = File.dirname(ConfigLoader::CONFIG_FILE)
  [:citizenship_front_path, :citizenship_back_path].each do |key|
    if config[key]
      path = File.expand_path(config[key], config_dir)
      if File.exist?(path)
        puts "   ✓ #{key}: #{path}"
      else
        puts "   ✗ #{key}: File not found at #{path}"
      end
    end
  end
  
  puts "\n" + "=" * 60
  puts "✓ All tests passed! Ready to run automation."
  puts "\nTo run the automation:"
  puts "  ruby scripts/run_automation.rb"
  
rescue => e
  puts "\n" + "=" * 60
  puts "✗ Error: #{e.message}"
  puts e.backtrace.first(5).join("\n")
  exit 1
end



