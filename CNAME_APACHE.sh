#!/bin/bash
exec 1> >(logger -s -t $(basename $0)) 2>&1

# Update the system package list
sudo apt update -y

# Install Apache and PHP
sudo apt install -y apache2 php libapache2-mod-php

# Enable Apache to start on boot
sudo systemctl enable apache2
sudo systemctl start apache2

# Remove the default Apache index.html page (if exists)
sudo rm -f /var/www/html/index.html

# Create a new PHP homepage
cat <<EOF | sudo tee /var/www/html/index.php
<?php
\$instance_ip = \$_SERVER['SERVER_ADDR']; // Get EC2 instance IP
\$instance_name = gethostname(); // Get EC2 instance hostname

echo "<h1>Welcome to My EC2 Instance</h1>";
echo "<p><strong>EC2 Machine IP Address:</strong> \$instance_ip</p>";
echo "<p><strong>EC2 Machine Name:</strong> \$instance_name</p>";
?>
EOF

# Set correct permissions for the web directory
sudo chown -R www-data:www-data /var/www/html/
sudo chmod -R 755 /var/www/html/

# Restart Apache to apply changes
sudo systemctl restart apache2

### Register Instance CNAME in Route 53 ###
# Download and install cli53 tool
wget https://github.com/barnybug/cli53/releases/download/0.8.5/cli53-linux-amd64 -O cli53
sudo mv cli53 /usr/bin/cli53
sudo chmod +x /usr/bin/cli53

# Define Route 53 Zone and CNAME entry
ZONE="aienergyservices.com"    # Your Route 53 Hosted Zone
MYNAME="nofilmachine"          # Desired CNAME alias

# Get EC2 public hostname
EC2_NAME=$(curl -s http://169.254.169.254/latest/meta-data/public-hostname)
FQN="$EC2_NAME."

# Log the DNS update
logger "ROUTE53: Setting DNS CNAME $MYNAME.$ZONE for $FQN"

# Create a new CNAME record on Route 53, replacing the old entry if necessary
/usr/bin/cli53 rrcreate --replace $ZONE "$MYNAME 60 CNAME $FQN"

