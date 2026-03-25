# UV Index Alert

A free, serverless UV index checker that runs on GitHub Actions and sends push notifications to your phone via [ntfy.sh](https://ntfy.sh).

## Setup (5 minutes)

### 1. Get a free OpenUV API key
Sign up at [openuv.io](https://www.openuv.io/) — free tier gives 50 requests/day.

### 2. Install ntfy on your phone
- **iPhone:** [App Store](https://apps.apple.com/us/app/ntfy/id1625396347)
- **Android:** [Play Store](https://play.google.com/store/apps/details?id=io.heckel.ntfy)

Open the app and subscribe to a topic name you make up (e.g. `my-uv-alerts-xyz`). Pick something unique so only you get the notifications.

### 3. Add secrets to this repo
Go to **Settings > Secrets and variables > Actions** and add:

| Secret | Description |
|---|---|
| `OPENUV_API_KEY` | Your OpenUV API key |
| `LATITUDE` | Your latitude (e.g. `37.7749`) |
| `LONGITUDE` | Your longitude (e.g. `-122.4194`) |
| `NTFY_TOPIC` | Your ntfy topic name (e.g. `my-uv-alerts-xyz`) |
| `UV_THRESHOLD` | *(optional)* UV threshold, defaults to `3` |

### 4. Test it
Go to **Actions > UV Index Check > Run workflow** to trigger a manual run.

## How It Works

- GitHub Actions runs the check daily at 2pm UTC (edit the cron in `.github/workflows/uv-check.yml`)
- Fetches the UV index for your coordinates from the OpenUV API
- If UV > 3, sends a push notification to your phone via ntfy.sh
- Completely free: GitHub Actions free tier + OpenUV free tier + ntfy.sh is free
