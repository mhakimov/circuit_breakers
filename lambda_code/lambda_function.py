import os
import json
import urllib.request
import random

API_URL = os.environ.get("API_URL")

def handler(event, context):
    for record in event["Records"]:
        body = record["body"]
        print(f"Processing message: {body}")

        # Simulate unstable downstream
        if random.random() < 0.7:  # 70% failure chance
            try:
                resp = urllib.request.urlopen(f"http://{API_URL}")
                print(f"Downstream response: {resp.status}")
            except Exception as e:
                print(f"Downstream failed: {e}")
        else:
            print("Simulating downstream success")

    return {"statusCode": 200}
