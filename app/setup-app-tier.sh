#!/bin/bash

# Exit immediately if a command exits with a non-zero status.
set -e

# --- Script Placeholders ---
# These will be replaced by the Bicep template.
DB_USER="__DB_USER__"
DB_PASSWORD="__DB_PASSWORD__"
DB_SERVER="__DB_SERVER__"
DB_DATABASE="__DB_DATABASE__"
APP_SOURCE_CODE="__APP_SOURCE_CODE__"

# --- Log Setup ---
LOG_FILE="/var/log/setup-app-tier.log"
exec > >(tee -a ${LOG_FILE})
exec 2> >(tee -a ${LOG_FILE} >&2)

echo "--- Starting App Tier setup on VMSS instance at $(date) ---"

# --- System & Node.js Installation ---
echo "Updating packages and installing Node.js, npm..."
apt-get update
apt-get install -y nodejs npm

# --- PM2 Installation ---
echo "Installing PM2 process manager globally..."
npm install pm2 -g

# --- Application Setup ---
APP_DIR="/opt/app"
echo "Creating application directory at ${APP_DIR}..."
mkdir -p ${APP_DIR}
cd ${APP_DIR}

echo "Creating app.js file by decoding the source code..."
# Decode the Base64 encoded source code and write it to app.js
echo "${APP_SOURCE_CODE}" | base64 --decode > ./app.js

echo "Installing npm dependencies (express, mssql, cors)..."
npm install express mssql cors

# --- PM2 Configuration ---
echo "Creating PM2 ecosystem file with environment variables..."
cat <<EOF > ecosystem.config.js
module.exports = {
  apps : [{
    name: 'app-tier-server',
    script: 'app.js',
    env: {
      NODE_ENV: 'production',
      DB_USER: '${DB_USER}',
      DB_PASSWORD: '${DB_PASSWORD}',
      DB_SERVER: '${DB_SERVER}',
      DB_DATABASE: '${DB_DATABASE}'
    }
  }]
};
EOF

# --- Start Application ---
echo "Starting application with PM2..."
pm2 start ecosystem.config.js

echo "Configuring PM2 to start on system boot..."
# The 'env' command is needed to ensure PM2 finds the right user home directory
env PATH=$PATH:/usr/bin pm2 startup systemd -u ${SUDO_USER:-root} --hp /home/${SUDO_USER:-root}
pm2 save

echo "--- App Tier setup script finished successfully at $(date) ---"