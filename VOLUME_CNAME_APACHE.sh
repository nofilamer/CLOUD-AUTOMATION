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

### Attach and Mount EBS Volume ###

# Define variables
VOLUME_ID="vol-076b6a73a52a8590b"
DEVICE_NAME="/dev/sdf"  # AWS name
MOUNT_POINT="/database"

# Attach the volume to this instance
INSTANCE_ID=$(curl -s http://169.254.169.254/latest/meta-data/instance-id)
aws ec2 attach-volume --volume-id $VOLUME_ID --instance-id $INSTANCE_ID --device $DEVICE_NAME --region us-east-1

# Wait for the volume to be attached
while [ ! -e /dev/xvdf ]; do
  sleep 5
done

# Create the mount point if it does not exist
sudo mkdir -p $MOUNT_POINT

# Mount the volume (Filesystem already exists)
sudo mount /dev/xvdf $MOUNT_POINT

# Ensure the mount persists across reboots
UUID=$(blkid -s UUID -o value /dev/xvdf)
echo "UUID=$UUID $MOUNT_POINT ext4 defaults,nofail 0 2" | sudo tee -a /etc/fstab

# Set proper permissions
sudo chown -R ubuntu:ubuntu $MOUNT_POINT
sudo chmod -R 755 $MOUNT_POINT

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

