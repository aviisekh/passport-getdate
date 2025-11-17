#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative '../services/appointment_automator'
require_relative '../config/config_loader'

# Main script to run appointment automation
begin
  # Load configuration
  puts "Loading configuration..."
  config = ConfigLoader.load
  
  # Validate configuration
  puts "Validating configuration..."
  ConfigLoader.validate(config)
  
  # Expand file paths relative to config directory
  config_dir = File.dirname(ConfigLoader::CONFIG_FILE)
  [:citizenship_front_path, :citizenship_back_path, :national_id_path].each do |key|
    if config[key] && !config[key].empty?
      expanded_path = File.expand_path(config[key], config_dir)
      config[key] = expanded_path if File.exist?(expanded_path)
    end
  end
  
  # Check if simple mode is requested (via command line argument or config)
  # use_simple = ARGV.include?('--simple') || config[:use_simple_mode] == true
  
  # Run automation
  automator = AppointmentAutomator.new(config)
  automator.run
  
  puts "\n✅ Appointment automation completed successfully!"
rescue => e
  puts "\n❌ Error: #{e.message}"
  puts e.backtrace.first(10).join("\n")
  exit 1
end



