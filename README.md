# UV Index Alert

A serverless function that checks the current UV index for your location and texts you a reminder when it's above 3. Runs on AWS Lambda with a daily CloudWatch schedule.

## Setup

1. **Get API keys:**
   - [OpenUV](https://www.openuv.io/) — free tier gives 50 requests/day
   - [Twilio](https://www.twilio.com/) — for sending SMS

2. **Install the AWS SAM CLI:**
   ```bash
   pip install aws-sam-cli
   ```

3. **Build and deploy:**
   ```bash
   sam build
   sam deploy --guided
   ```
   SAM will prompt you for your API keys, phone numbers, and coordinates during the guided deploy.

4. **Test it:**
   ```bash
   sam remote invoke UvAlertFunction --stack-name uv-index-alert
   ```

## Run Locally

```bash
pip install -r requirements.txt
# Set env vars (or source .env)
python uv_alert.py
```

## Architecture

- **AWS Lambda** — runs the check (Python 3.12, 128 MB, ~30s timeout)
- **CloudWatch Events** — triggers the Lambda daily at 2pm UTC (adjust the cron in `template.yaml`)
- **OpenUV API** — provides the UV index
- **Twilio** — sends the SMS alert

## Configuration

All parameters are set during `sam deploy --guided` and stored as CloudFormation parameters:

| Parameter | Description |
|---|---|
| `OpenUvApiKey` | Your OpenUV API key |
| `Latitude` | Your latitude |
| `Longitude` | Your longitude |
| `TwilioAccountSid` | Twilio account SID |
| `TwilioAuthToken` | Twilio auth token |
| `TwilioFromNumber` | Twilio phone number (sender) |
| `ToNumber` | Your phone number (receiver) |
| `UvThreshold` | UV index threshold (default: 3) |

To change the schedule, edit the `Schedule` in `template.yaml` and redeploy.
