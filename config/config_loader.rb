#!/usr/bin/env ruby
# frozen_string_literal: true

require 'yaml'
require 'fileutils'
require 'pry-rails'

# Configuration loader for appointment automation
class ConfigLoader
  CONFIG_FILE = File.join(__dir__, 'config.yml')
  EXAMPLE_CONFIG = File.join(__dir__, 'config.example.yml')

  def self.load
    unless File.exist?(CONFIG_FILE)
      if File.exist?(EXAMPLE_CONFIG)
        puts "Config file not found. Please copy #{EXAMPLE_CONFIG} to #{CONFIG_FILE} and fill in your details."
        exit 1
      else
        puts "Config file not found: #{CONFIG_FILE}"
        exit 1
      end
    end

    config = YAML.load_file(CONFIG_FILE)
    
    # Convert keys to symbols for easier access
    symbolize_keys(config)
  end

  def self.validate(config)
    errors = []
    
    # Check required file paths
    [:citizenship_front_path, :citizenship_back_path].each do |key|
      path = config[key]
      if path.nil? || path.empty?
        errors << "Missing required file path: #{key}"
      elsif !File.exist?(File.expand_path(path, __dir__))
        errors << "File not found: #{path}"
      end
    end
    
    # Check required form data fields
    required_fields = [
      :lastName, :firstName, :dateOfBirth, :citizenNum,
      :email, :contactPhone
    ]
    
    form_data = config[:form_data] || {}
    required_fields.each do |field|
      if form_data[field].nil? || form_data[field].empty?
        errors << "Missing required form field: #{field}"
      end
    end
    
    if errors.any?
      puts "Configuration errors:"
      errors.each { |e| puts "  - #{e}" }
      exit 1
    end
    
    true
  end

  private

  def self.symbolize_keys(hash)
    case hash
    when Hash
      hash.each_with_object({}) do |(key, value), result|
        new_key = key.is_a?(String) ? key.to_sym : key
        new_value = value.is_a?(Hash) ? symbolize_keys(value) : value
        result[new_key] = new_value
      end
    when Array
      hash.map { |item| item.is_a?(Hash) ? symbolize_keys(item) : item }
    else
      hash
    end
  end
end



