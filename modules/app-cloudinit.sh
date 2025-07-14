#!/bin/bash

apt-get update
apt-get install -y python3-pip
pip3 install flask pyodbc

# Create Flask App
cat <<EOF > /home/azureuser/app_tier.py
from flask import Flask, jsonify
import os
import pyodbc

app = Flask(__name__)
DB_CONN = os.getenv('DB_CONN', 'Driver={ODBC Driver 18 for SQL Server};Server=tcp:<DB_SERVER>;Database=<DB_NAME>;Uid=<USER>;Pwd=<PASS>;Encrypt=yes;TrustServerCertificate=no;')

@app.route('/get-message')
def get_message():
    try:
        conn = pyodbc.connect(DB_CONN)
        cursor = conn.cursor()
        cursor.execute("SELECT TOP 1 message FROM TestMessages")
        row = cursor.fetchone()
        return jsonify({'message': row[0] if row else 'No data'})
    except Exception as e:
        return jsonify({'error': str(e)}), 500

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
EOF

# Set environment variable
echo "export DB_CONN='<REPLACE_WITH_CONN_STRING>'" >> /etc/profile

# Create systemd service
cat <<EOF > /etc/systemd/system/apptier.service
[Unit]
Description=App Tier API
After=network.target

[Service]
ExecStart=/usr/bin/python3 /home/azureuser/app_tier.py
Environment=DB_CONN='<REPLACE_WITH_CONN_STRING>'
Restart=always
User=root

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable apptier.service
systemctl start apptier.service
