# UV Index Alert

A simple script that checks the current UV index for your location and texts you a reminder when it's above 3 (or your custom threshold).

## Setup

1. **Get API keys:**
   - [OpenUV](https://www.openuv.io/) — free tier gives 50 requests/day
   - [Twilio](https://www.twilio.com/) — for sending SMS

2. **Install dependencies:**
   ```bash
   pip install -r requirements.txt
   ```

3. **Configure environment variables:**
   ```bash
   cp .env.example .env
   # Edit .env with your API keys, phone number, and coordinates
   ```

4. **Run:**
   ```bash
   python uv_alert.py
   ```

## Schedule It

Use cron to check every morning:
```bash
# Run at 8 AM daily
0 8 * * * cd /path/to/uv-index-alert && source .env && python uv_alert.py
```

## Environment Variables

| Variable | Description |
|---|---|
| `OPENUV_API_KEY` | Your OpenUV API key |
| `LATITUDE` | Your latitude |
| `LONGITUDE` | Your longitude |
| `TWILIO_ACCOUNT_SID` | Twilio account SID |
| `TWILIO_AUTH_TOKEN` | Twilio auth token |
| `TWILIO_FROM_NUMBER` | Twilio phone number (sender) |
| `TO_NUMBER` | Your phone number (receiver) |
| `UV_THRESHOLD` | UV index threshold (default: 3) |
