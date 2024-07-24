#!/bin/bash

# Ensure the script is run as root
if [ "$EUID" -ne 0 ]; then
    echo "Please run as root."
    exit 1
fi

# Install necessary dependencies
echo "Installing dependencies..."
apt update
apt install -y net-tools docker.io nginx logrotate

# Create the monitoring script
echo "Creating the monitoring script..."
cp devopsfetch /usr/local/bin/devopsfetch
chmod +x /usr/local/bin/devopsfetch
#!/bin/bash

LOGFILE="/var/log/devopsfetch.log"

# Function to log messages
log_message() {
    echo "$(date): $@" >> $LOGFILE
}

# Continuous monitoring mode
while true; do
    log_message "Checking system status..."
    # Add your monitoring commands here, e.g., checking active ports
    netstat -tulnp >> $LOGFILE 2>&1
    docker ps >> $LOGFILE 2>&1
    nginx -T >> $LOGFILE 2>&1
    sleep 300
done
EOF

chmod +x /usr/local/bin/devopsfetch

# Create the systemd service unit file
echo "Creating systemd service..."
cat << 'EOF' > /etc/systemd/system/devopsfetch.service
[Unit]
Description=DevOps Fetch Monitoring Service

[Service]
ExecStart=/usr/local/bin/devopsfetch
Restart=always
User=root
Group=root

[Install]
WantedBy=multi-user.target
EOF

# Reload systemd, enable and start the service
echo "Starting the service..."
systemctl daemon-reload
systemctl enable devopsfetch.service
systemctl start devopsfetch.service

# Set up log rotation
echo "Setting up log rotation..."
cat << 'EOF' > /etc/logrotate.d/devopsfetch
/var/log/devopsfetch.log {
    daily
    missingok
    rotate 7
    compress
    delaycompress
    notifempty
    create 0640 nobody nogroup
    sharedscripts
    postrotate
        systemctl reload devopsfetch.service > /dev/null 2>&1 || true
    endscript
}
EOF

echo "Setup complete."
