#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative 'passport_api_service'
require 'base64'
require 'tempfile'

# Service for handling CAPTCHA challenges during appointment booking
class CaptchaHandler
  def initialize(api_service)
    @api_service = api_service
  end

  # Get captcha challenge from API
  # Returns hash with captcha data (image, challenge ID, etc.)
  def get_captcha
    begin
      captcha_data = @api_service.get_captcha_challenge
      log("Captcha challenge received")
      captcha_data
    rescue => e
      log("Error fetching captcha: #{e.message}")
      raise "Failed to get captcha challenge: #{e.message}"
    end
  end

  # Solve captcha manually by displaying image and asking user for input
  # @param captcha_data [Hash] The captcha data from API (with captchaId and captchaImage)
  # @return [Hash] Hash with :captcha_id and :captcha_text keys
  def solve_captcha_manually(captcha_data)
    # Extract captcha ID from response
    captcha_id = captcha_data['captchaId'] || captcha_data[:captchaId]
    
    # Try to extract captcha image
    image_data = extract_captcha_image(captcha_data)
    
    if image_data
      # Save captcha image to temp file and display path
      captcha_file = save_captcha_image(image_data)
      log("=" * 60)
      log("⚠️  CAPTCHA REQUIRED!")
      log("Captcha ID: #{captcha_id}")
      log("Captcha image saved to: #{captcha_file}")
      log("Please open the image and solve the captcha.")
      log("=" * 60)
      
      print "Enter captcha code: "
      captcha_text = STDIN.gets.chomp
      
      # Clean up temp file
      File.delete(captcha_file) if File.exist?(captcha_file)
      
      {
        captcha_id: captcha_id,
        captcha_text: captcha_text
      }
    else
      # If no image, just ask for code
      log("=" * 60)
      log("⚠️  CAPTCHA REQUIRED!")
      log("Captcha ID: #{captcha_id}")
      log("Please check the browser/API response for captcha details.")
      log("=" * 60)
      print "Enter captcha code: "
      captcha_text = STDIN.gets.chomp
      
      {
        captcha_id: captcha_id,
        captcha_text: captcha_text
      }
    end
  end

  # Extract captcha image from API response
  # Handles different response formats (base64, URL, etc.)
  def extract_captcha_image(captcha_data)
    if captcha_data.is_a?(Hash)
      # Try different possible keys for image data
      image_data = captcha_data['image'] || 
                   captcha_data['imageData'] || 
                   captcha_data['data'] ||
                   captcha_data['captchaImage'] ||
                   captcha_data[:image] ||
                   captcha_data[:imageData]
      
      # If it's a URL, we might need to fetch it
      if image_data.is_a?(String) && image_data.start_with?('http')
        # Could fetch the image here if needed
        return nil
      end
      
      image_data
    else
      captcha_data
    end
  end

  # Save captcha image to temporary file
  def save_captcha_image(image_data)
    file_ext = 'png' # default
    
    # Handle base64 encoded images
    if image_data.is_a?(String)
      # Check if it's base64 with data URI prefix
      if image_data.match?(/^data:image\/(png|jpeg|jpg|gif);base64,/)
        # Extract base64 part and determine file extension from MIME type
        mime_match = image_data.match(/^data:image\/(png|jpeg|jpg|gif);base64,/)
        file_ext = mime_match[1] == 'jpeg' || mime_match[1] == 'jpg' ? 'jpg' : 'png'
        base64_data = image_data.split(',')[1]
        image_data = Base64.decode64(base64_data)
      elsif image_data.match?(/^[A-Za-z0-9+\/=\s]+$/)
        # Pure base64 string (may include whitespace)
        # Detect format from base64 string before decoding
        clean_base64 = image_data.gsub(/\s+/, '')
        if clean_base64.start_with?('/9j/') || clean_base64.start_with?('iVBORw0KGgo')
          file_ext = clean_base64.start_with?('/9j/') ? 'jpg' : 'png'
        end
        
        begin
          image_data = Base64.decode64(clean_base64)
          # Verify by checking decoded binary magic bytes
          if image_data.is_a?(String) && image_data.length >= 3
            if image_data[0..2] == "\xFF\xD8\xFF"
              file_ext = 'jpg'
            elsif image_data[0..7] == "\x89PNG\r\n\x1a\n"
              file_ext = 'png'
            end
          end
        rescue => e
          log("Warning: Failed to decode base64 image: #{e.message}")
          # Not base64, treat as binary
        end
      end
    end

    permanent_path = File.expand_path("captcha_#{Time.now.to_i}.#{file_ext}", Dir.pwd)
    File.open(permanent_path, 'wb') do |f|
      f.write(image_data)
    end
    
    permanent_path
  end

  def log(message)
    puts "[#{Time.now.strftime('%Y-%m-%d %H:%M:%S')}] #{message}"
  end
end

