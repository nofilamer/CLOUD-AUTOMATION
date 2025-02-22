#!/bin/bash
exec 1> >(logger -s -t $(basename $0)) 2>&1

### Install AWS CLI ###
echo "Installing AWS CLI..."
sudo apt update -y
sudo apt install -y unzip curl

# Check if AWS CLI is already installed
if ! command -v aws &> /dev/null; then
    curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
    unzip awscliv2.zip
    sudo ./aws/install
    rm -rf aws awscliv2.zip
fi

# Verify AWS CLI installation
aws --version

### Existing User-Data Script Begins Here ###

# Update the system package list
sudo apt update -y

# Install Apache and PHP
sudo apt install -y apache2 php libapache2-mod-php

# Enable Apache to start on boot
sudo systemctl enable apache2
sudo systemctl start apache2

# Remove the default Apache index.html page (if exists)
sudo rm -f /var/www/html/index.html
sudo systemctl enable apache2
sudo systemctl start apache2
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
