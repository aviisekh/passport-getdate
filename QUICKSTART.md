# Quick Start Guide

Get your passport appointment automation up and running in 5 minutes!

## Step 1: Install Dependencies

```bash
cd appointment_automation
bundle install
```

## Step 2: Create Configuration

```bash
cp config/config.example.yml config/config.yml
```

## Step 3: Fill in Your Details

Edit `config/config.yml` and update:

1. **File paths** - Point to your citizenship certificate images:
   ```yaml
   citizenship_front_path: "../beemla/front.jpeg"
   citizenship_back_path: "../beemla/back.jpeg"
   ```

2. **Personal information** - Fill in all the form fields:
   - Name, date of birth, citizenship number
   - Contact details (phone, email)
   - Address information
   - Family details

3. **Location** (if different from default):
   ```yaml
   location_id: 79  # DOP (Tripureshwor) - change if needed
   ```

## Step 4: Test Your Setup

```bash
ruby scripts/test_connection.rb
```

This verifies:
- ✅ Configuration is valid
- ✅ API connection works
- ✅ Files are accessible

## Step 5: Run Automation

### Option A: Local Run

```bash
ruby scripts/run_automation.rb
```

The script will:
1. Wait until 5pm today
2. Monitor for available appointments
3. Book the first slot between 5pm-6pm
4. Upload files and submit form

### Option B: GitHub Actions (Recommended)

1. **Add your config as a secret**:
   - Go to: Repository → Settings → Secrets and variables → Actions
   - Click "New repository secret"
   - Name: `CONFIG_YML`
   - Value: Copy entire contents of your `config/config.yml`

2. **Commit and push**:
   ```bash
   git add appointment_automation/
   git commit -m "Add appointment automation"
   git push
   ```

3. **Schedule or trigger manually**:
   - The workflow runs daily at 4:55 PM Nepal Time
   - Or trigger manually from Actions tab

## Important Notes

⚠️ **CAPTCHA Handling**: The passport office website uses CAPTCHAs. The script will fail at those steps. Options:

1. **Monitor and solve manually** - Watch the script and solve CAPTCHAs when they appear
2. **Use a CAPTCHA service** - Integrate 2Captcha or similar (requires code changes)
3. **Hybrid approach** - Use script to monitor, then complete booking manually

⚡ **Concurrent Requests**: The script uses **5 parallel requests** by default to increase your chances of securing a slot in the competitive booking window. This means:
- 5x faster checking for available slots
- Multiple simultaneous booking attempts
- Better chance of success when slots open

You can adjust this in `config/config.yml`:
```yaml
concurrent_requests: 5  # Increase for more aggressive booking (but watch for rate limits)
poll_interval: 0.1      # Decrease for faster polling (but may hit rate limits)
```

## Troubleshooting

**"Config file not found"**
- Make sure you copied `config.example.yml` to `config.yml`

**"File not found"**
- Check file paths in config are correct
- Use absolute paths if relative paths don't work

**"No appointments found"**
- Booking window might not be open yet
- All slots might be booked
- Check calendar API response

**"CAPTCHA error"**
- This is expected - see "Important Notes" above

## Next Steps

- Read the full [README.md](README.md) for detailed documentation
- Customize the booking time window if needed
- Set up notifications (email/SMS) for successful bookings

