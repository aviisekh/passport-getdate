# Passport Appointment Automation

Automated script to book passport appointments online for Nepal Passport Office.

## Features

- **Continuous Polling**: Continuously polls the time slots endpoint (default: every 50ms) to catch slots the moment they become available
- **Concurrent Requests**: Uses multiple parallel requests (default: 5) to increase chances of securing a slot
- **Immediate Booking**: Attempts to book slots immediately when found - no delays
- **Parallel Booking**: Attempts to book multiple available slots simultaneously
- **Smart Polling**: Skips calendar checks after initial verification - focuses only on time slots endpoint
- Automatically monitors for available appointment slots
- Books appointments between 5pm-6pm when the booking window opens
- Handles file uploads (citizenship certificates, national ID)
- Submits complete application form
- Designed to run in GitHub Actions for automated scheduling

## Important Notes

⚠️ **CAPTCHA HANDLING**: The real passport office website uses CAPTCHAs during appointment creation and form submission. This script will fail at those steps. You have a few options:

1. **Manual Intervention**: Monitor the script and manually solve CAPTCHAs when they appear
2. **CAPTCHA Solving Service**: Integrate a service like 2Captcha, AntiCaptcha, or similar
3. **Hybrid Approach**: Use the script to monitor and notify you, then manually complete the booking

## Setup

### 1. Install Dependencies

```bash
cd appointment_automation
bundle install
```

### 2. Configure

1. Copy the example config file:
```bash
cp config/config.example.yml config/config.yml
```

2. Edit `config/config.yml` and fill in:
   - Your personal information
   - File paths to citizenship certificates
   - Location preferences
   - Contact details

### 3. Prepare Files

Ensure your citizenship certificate files are accessible:
- Citizenship Certificate Front (JPEG)
- Citizenship Certificate Back (JPEG)
- National eID (JPEG, optional)

Update the file paths in `config/config.yml`.

## Usage

### Test Setup First

Before running the automation, test your configuration:

```bash
cd appointment_automation
ruby scripts/test_connection.rb
```

This will verify:
- Configuration file is valid
- API connection works
- File paths are correct

### Local Run

```bash
cd appointment_automation
ruby scripts/run_automation.rb
```

The script will:
1. Wait until 5pm today
2. Start monitoring for available appointments for tomorrow
3. Book the first available slot between 5pm-6pm
4. Upload required files
5. Submit the application form

**Note**: The script will fail at CAPTCHA steps. See "Important Notes" section above.

### GitHub Actions

1. **Add Configuration as Secret**:
   - Go to your GitHub repository
   - Settings → Secrets and variables → Actions
   - Add a new secret named `CONFIG_YML`
   - Paste the contents of your `config/config.yml` file

2. **Update Workflow Schedule**:
   - Edit `.github/workflows/book-appointment.yml`
   - Adjust the cron schedule to match Nepal timezone
   - Current: Runs daily at 4:55 PM Nepal Time (adjust as needed)

3. **Manual Trigger**:
   - You can also manually trigger the workflow from GitHub Actions tab

## Configuration Reference

### Location IDs

From `get_dates.rb`:
- **DOP (Tripureshwor)**: 79 (default in config)
- **KTM**: 78
- **Kanchanpur**: 45
- **Dailekh**: 21

**Note**: If you need a different location ID, update `location_id` in `config/config.yml`

### Service Codes

- `PP_FIRSTISSUANCE`: First time passport issuance
- `PP_RENEWAL`: Passport renewal

### Performance Settings

You can adjust performance settings in `config/config.yml`:

```yaml
concurrent_requests: 5  # Number of parallel requests (default: 5)
poll_interval: 0.05     # Seconds between polling attempts (default: 0.05 = 50ms)
```

**Note**: 
- The script continuously polls the time slots endpoint - this is the critical part for securing slots
- Increasing `concurrent_requests` may improve your chances but could also trigger rate limiting
- Decreasing `poll_interval` makes polling faster but may hit rate limits
- Start with the defaults (5 requests, 50ms interval) and adjust if needed

### District Codes

Common district codes:
- `BAG`: Bagmati
- `GOR`: Gorkha
- `ARG`: Arghakhanchi
- `ACM`: Achham

## Troubleshooting

### Script fails with "Config file not found"
- Ensure `config/config.yml` exists
- Copy from `config/config.example.yml` if needed

### File upload fails
- Check file paths in config are correct
- Ensure files exist and are readable
- Verify file format is JPEG

### No appointments found
- The booking window might not be open yet
- All slots might be booked
- Check the calendar API response for available dates

### CAPTCHA errors
- This is expected - see "Important Notes" section above
- Consider integrating a CAPTCHA solving service

## Development

### Project Structure

```
appointment_automation/
├── lib/
│   ├── passport_api_service.rb    # API interaction service
│   └── appointment_automator.rb   # Main automation logic
├── config/
│   ├── config.example.yml         # Example configuration
│   ├── config.yml                  # Your configuration (gitignored)
│   └── config_loader.rb            # Configuration loader
├── scripts/
│   └── run_automation.rb           # Main entry point
├── .github/
│   └── workflows/
│       └── book-appointment.yml   # GitHub Actions workflow
├── Gemfile                          # Ruby dependencies
└── README.md                        # This file
```

## License

Use at your own risk. This is for personal use only.

## Disclaimer

This script is provided as-is. The passport office may change their API or add additional security measures. Always verify your appointment was successfully booked through the official website.

