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
ADMIN_USER="__ADMIN_USER__" # Placeholder for the admin username

# --- Log Setup ---
LOG_FILE="/var/log/setup-app-tier.log"
exec > >(tee -a ${LOG_FILE})
exec 2> >(tee -a ${LOG_FILE} >&2)

echo "--- Starting App Tier setup on VMSS instance at $(date) ---"

# --- System & Node.js Installation ---
echo "Updating packages and installing Node.js, npm..."
# Add a retry loop to handle transient network issues
for i in {1..5}; do apt-get update && break || sleep 15; done
apt-get install -y nodejs npm

# --- PM2 Installation ---
echo "Installing PM2 process manager globally..."
npm install pm2 -g

# --- Application Setup ---
APP_DIR="/opt/app"
echo "Creating application directory at ${APP_DIR}..."
mkdir -p ${APP_DIR}

echo "Creating app.js file by decoding the source code..."
# Decode the Base64 encoded source code and write it to app.js
echo "${APP_SOURCE_CODE}" | base64 --decode > ${APP_DIR}/app.js

# --- Change Ownership and Install Dependencies as the Correct User ---
echo "Changing ownership of ${APP_DIR} to ${ADMIN_USER}..."
chown -R ${ADMIN_USER}:${ADMIN_USER} ${APP_DIR}

echo "Installing npm dependencies as user ${ADMIN_USER}..."
# Run npm install as the admin user to avoid permission issues
sudo -u ${ADMIN_USER} npm --prefix ${APP_DIR} install express mssql cors

# --- PM2 Configuration ---
echo "Creating PM2 ecosystem file with environment variables..."
cat <<EOF > ${APP_DIR}/ecosystem.config.js
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
# Ensure the ecosystem file is also owned by the admin user
chown ${ADMIN_USER}:${ADMIN_USER} ${APP_DIR}/ecosystem.config.js


# --- Start Application as the correct user ---
echo "Starting application with PM2 as user ${ADMIN_USER}..."
sudo -u ${ADMIN_USER} pm2 start ${APP_DIR}/ecosystem.config.js

# Generate the startup script configuration for the admin user
echo "Configuring PM2 to start on system boot for user ${ADMIN_USER}..."
# Get the startup command from pm2
STARTUP_COMMAND=$(sudo -u ${ADMIN_USER} pm2 startup | tail -n 1)
# Execute the generated command as root
eval "${STARTUP_COMMAND}"

# Save the process list for the admin user
sudo -u ${ADMIN_USER} pm2 save

echo "--- App Tier setup script finished successfully at $(date) ---"