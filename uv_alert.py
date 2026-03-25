#!/usr/bin/env python3
"""UV Index Alert - AWS Lambda function that checks UV index and texts you."""

import os
import requests
from twilio.rest import Client


def get_uv_index(api_key, lat, lng):
    """Fetch current UV index from OpenUV API."""
    url = "https://api.openuv.io/api/v1/uv"
    headers = {"x-access-token": api_key}
    params = {"lat": lat, "lng": lng}
    resp = requests.get(url, headers=headers, params=params, timeout=10)
    resp.raise_for_status()
    return resp.json()["result"]["uv"]


def send_sms(account_sid, auth_token, from_number, to_number, message):
    """Send an SMS via Twilio."""
    client = Client(account_sid, auth_token)
    client.messages.create(body=message, from_=from_number, to=to_number)


def handler(event, context):
    """AWS Lambda entry point."""
    openuv_api_key = os.environ["OPENUV_API_KEY"]
    lat = os.environ["LATITUDE"]
    lng = os.environ["LONGITUDE"]
    twilio_sid = os.environ["TWILIO_ACCOUNT_SID"]
    twilio_token = os.environ["TWILIO_AUTH_TOKEN"]
    twilio_from = os.environ["TWILIO_FROM_NUMBER"]
    to_number = os.environ["TO_NUMBER"]
    threshold = float(os.environ.get("UV_THRESHOLD", "3"))

    uv = get_uv_index(openuv_api_key, lat, lng)
    print(f"Current UV index: {uv}")

    if uv > threshold:
        message = (
            f"UV Alert: The current UV index is {uv:.1f}, "
            f"which is above your threshold of {threshold:.0f}. "
            "Don't forget sunscreen!"
        )
        send_sms(twilio_sid, twilio_token, twilio_from, to_number, message)
        print(f"Alert sent: {message}")
        return {"statusCode": 200, "body": f"Alert sent. UV index: {uv:.1f}"}

    print(f"UV index {uv:.1f} is at or below threshold ({threshold:.0f}). No alert needed.")
    return {"statusCode": 200, "body": f"No alert. UV index: {uv:.1f}"}


if __name__ == "__main__":
    handler(None, None)
