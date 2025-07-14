# web_tier.py
from flask import Flask, jsonify
import requests

app = Flask(__name__)
APP_TIER_URL = "http://<app-tier-ip>:5000/get-message"

@app.route('/')
def index():
    try:
        res = requests.get(APP_TIER_URL)
        return f"App Tier Response: {res.json()}"
    except Exception as e:
        return f"Failed to connect to app tier: {e}"

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=80)
