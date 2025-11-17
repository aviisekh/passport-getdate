#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative '../lib/passport_api_service'
require 'json'

# Service for handling file uploads for passport applications
# Handles uploading citizenship certificates and national ID documents
class FileUploadService
  # File metadata definitions - shared between upload and pieces array
  FILE_DEFINITIONS = {
    front: {
      name: "Citizenship Certificate Front",
      mime_type: "image/jpeg",
      label: "Citizenship Certificate Front",
      type: "Citizenship Certificate"
    },
    back: {
      name: "Citizenship Certificate Back",
      mime_type: "image/jpeg",
      label: "Citizenship Certificate Back",
      type: "Citizenship Certificate"
    },
    national_id: {
      name: "National eID",
      mime_type: "image/jpeg",
      label: "National eID",
      type: "National eID"
    }
  }.freeze

  def initialize(api_service:, config:)
    @api_service = api_service
    @config = config
    @pieces = nil # Cache uploaded pieces array
  end

  # Upload all required files and return pieces array ready for form submission
  # @return [Array] Array of piece hashes ready for form submission
  def upload_required_files
    return @pieces if @pieces # Return cached pieces
    
    log("Uploading required files...")
    @pieces = []
    
    # Upload citizenship front
    if @config[:citizenship_front_path]
      piece = upload_and_build_piece(:front, @config[:citizenship_front_path])
      @pieces << piece if piece
    end
    
    # Upload citizenship back
    if @config[:citizenship_back_path]
      piece = upload_and_build_piece(:back, @config[:citizenship_back_path])
      @pieces << piece if piece
    end
    
    # Upload national ID if provided
    if @config[:national_id_path]
      piece = upload_and_build_piece(:national_id, @config[:national_id_path])
      @pieces << piece if piece
    end
    
    @pieces
  end

  private

  # Upload a file and build the piece hash in one step
  # @param file_type [Symbol] One of :front, :back, :national_id
  # @param file_path [String] Path to the file to upload
  # @return [Hash, nil] Piece hash ready for form submission or nil if upload failed
  def upload_and_build_piece(file_type, file_path)
    definition = FILE_DEFINITIONS[file_type]
    return nil unless definition
    
    # Build metadata for upload
    upload_meta = {
      "name" => definition[:name],
      "mimeType" => definition[:mime_type],
      "label" => definition[:label],
      "type" => definition[:type]
    }
    
    # Upload file
    file_response = @api_service.upload_file(file_path, upload_meta)
    log("#{definition[:name]} uploaded: #{file_response}")
    
    # Extract file value from response
    value = extract_file_value(file_response)
    return nil unless value
    
    # Build and return piece hash
    upload_meta.merge(value: value)
  end

  def extract_file_value(file_response)
    # API response can be a hash with 'reference' key, or the value might be in the response body
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

  def log(message)
    puts "[#{Time.now.strftime('%Y-%m-%d %H:%M:%S')}] #{message}"
  end
end

