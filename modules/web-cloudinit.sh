#!/bin/bash

apt-get update
apt-get install -y python3-pip
pip3 install flask requests

# Web Tier Flask App
cat <<EOF > /home/azureuser/web_tier.py
from flask import Flask
import os
import requests

app = Flask(__name__)
APP_TIER_URL = os.getenv('APP_TIER_URL', 'http://<APP_TIER_IP>:5000/get-message')

@app.route('/')
def index():
    try:
        res = requests.get(APP_TIER_URL)
        return f"App Tier Response: {res.json()}"
    except Exception as e:
        return f"Error: {e}"

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=80)
EOF

# Environment variable
echo "export APP_TIER_URL=http://<APP_TIER_IP>:5000/get-message" >> /etc/profile

# Systemd service
cat <<EOF > /etc/systemd/system/webtier.service
[Unit]
Description=Flask Web App Tier
After=network.target

[Service]
ExecStart=/usr/bin/python3 /home/azureuser/web_tier.py
Environment=APP_TIER_URL=http://<APP_TIER_IP>:5000/get-message
Restart=always
User=root

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable webtier.service
systemctl start webtier.service
