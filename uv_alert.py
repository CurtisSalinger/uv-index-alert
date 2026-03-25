#!/usr/bin/env python3
"""UV Index Alert - Checks UV index and sends a push notification via ntfy.sh."""

import os
import requests


def get_uv_index(api_key, lat, lng):
    """Fetch current UV index from OpenUV API."""
    url = "https://api.openuv.io/api/v1/uv"
    headers = {"x-access-token": api_key}
    params = {"lat": lat, "lng": lng}
    resp = requests.get(url, headers=headers, params=params, timeout=10)
    resp.raise_for_status()
    return resp.json()["result"]["uv"]


def send_notification(topic, title, message):
    """Send a push notification via ntfy.sh (free, no account needed)."""
    requests.post(
        f"https://ntfy.sh/{topic}",
        data=message,
        headers={"Title": title, "Priority": "high", "Tags": "sun,warning"},
        timeout=10,
    )


def main():
    api_key = os.environ["OPENUV_API_KEY"]
    lat = os.environ["LATITUDE"]
    lng = os.environ["LONGITUDE"]
    ntfy_topic = os.environ["NTFY_TOPIC"]
    threshold = float(os.environ.get("UV_THRESHOLD", "3"))

    uv = get_uv_index(api_key, lat, lng)
    print(f"Current UV index: {uv}")

    if uv > threshold:
        message = (
            f"The current UV index is {uv:.1f} "
            f"(above your threshold of {threshold:.0f}). "
            "Don't forget sunscreen!"
        )
        send_notification(ntfy_topic, "UV Index Alert", message)
        print(f"Alert sent: {message}")
    else:
        print(f"UV index {uv:.1f} is at or below threshold ({threshold:.0f}). No alert needed.")


if __name__ == "__main__":
    main()
