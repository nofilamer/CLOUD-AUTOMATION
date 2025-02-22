#!/bin/bash
exec 1> >(logger -s -t $(basename $0)) 2>&1
# Download and install cli53 tool. We need it to update route53 record
wget https://github.com/barnybug/cli53/releases/download/0.8.5/cli53-linux-amd64
sudo mv cli53-linux-amd64 /usr/bin/cli53
sudo chmod +x /usr/bin/cli53
ZONE="aienergyservices.com"                        # cloudstudents.net
MYNAME="nofilmachine"        		   # nflx
EC2_NAME=`/usr/bin/curl -s http://169.254.169.254/latest/meta-data/public-hostname| cut -d ' ' -f 2`
# Append dot to make it a fully qualified name to avoid getting domainname appended
FQN="$EC2_NAME."

# Search for this string in /var/log/syslog file to see if it worked
logger "ROUTE53: Setting DNS CNAME $MYNAME.$ZONE for $FQN_EC2_NAME"

# Create a new CNAME record on Route 53, replacing the old entry if necessary. 
# CNAME myserver is created pointing to an ec2 instance public address. 
# Make sure to have a dot at the end to make it fully qualified name
/usr/bin/cli53 rrcreate --replace $ZONE "$MYNAME 60 CNAME $FQN"
