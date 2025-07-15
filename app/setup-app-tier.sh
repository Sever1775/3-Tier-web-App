#!/bin/bash

# Exit immediately if a command exits with a non-zero status.
set -e

# --- Script Placeholders ---
DB_USER="__DB_USER__"
DB_PASSWORD="__DB_PASSWORD__"
DB_SERVER="__DB_SERVER__"
DB_DATABASE="__DB_DATABASE__"
APP_SOURCE_CODE="__APP_SOURCE_CODE__"
ADMIN_USER="__ADMIN_USER__"

# --- Log Setup ---
LOG_FILE="/var/log/setup-app-tier.log"
exec > >(tee -a ${LOG_FILE})
exec 2> >(tee -a ${LOG_FILE} >&2)

echo "--- Starting App Tier setup on VMSS instance at $(date) ---"

# --- System & Node.js Installation ---
echo "Updating packages and installing Node.js, npm..."
for i in {1..5}; do apt-get update && break || sleep 15; done
apt-get install -y nodejs npm

# --- PM2 Installation ---
echo "Installing PM2 process manager globally..."
npm install -g pm2

NODE_PATH=$(which node)

# --- Application Setup ---
APP_DIR="/opt/app"
echo "Creating application directory at ${APP_DIR}..."
mkdir -p ${APP_DIR}
echo "${APP_SOURCE_CODE}" | base64 --decode > ${APP_DIR}/app.js

# --- Set ownership ---
chown -R ${ADMIN_USER}:${ADMIN_USER} ${APP_DIR}

# --- Dependency Installation ---
echo "Installing required Node.js modules..."
cd ${APP_DIR}
sudo -u ${ADMIN_USER} npm init -y
sudo -u ${ADMIN_USER} npm install express mssql cors

# --- PM2 Configuration ---
echo "Creating PM2 ecosystem config..."
cat <<EOF > ${APP_DIR}/ecosystem.config.js
module.exports = {
  apps : [{
    name: 'app-tier-server',
    script: '${APP_DIR}/app.js',
    interpreter: '${NODE_PATH}',
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

chown ${ADMIN_USER}:${ADMIN_USER} ${APP_DIR}/ecosystem.config.js

# --- Start App ---
echo "Starting app with PM2..."
sudo -u ${ADMIN_USER} pm2 start ${APP_DIR}/ecosystem.config.js

# --- PM2 Startup ---
echo "Configuring PM2 startup..."
STARTUP_COMMAND=$(sudo -u ${ADMIN_USER} pm2 startup | tail -n 1)
eval "${STARTUP_COMMAND}"
sudo -u ${ADMIN_USER} pm2 save

echo "--- App Tier setup completed successfully at $(date) ---"
