#!/bin/bash
#enter sudo exit if not sudo
if [[ $(id -u) != "0" ]]; then
    echo "Error: script not running as root or with sudo! Exiting..."
    exit 1
fi

#prompt user for hostname
read -p "Enter a hostname name(Name of your webserver): " user_hostname

#Set cloud to false
sudo bash -c 'awk "/^preserve_hostname: false\$/ {\$2=\"true\"} 1" /etc/cloud/cloud.cfg > /etc/cloud/cloud.cfg.tmp && mv /etc/cloud/cloud.cfg.tmp /etc/cloud/cloud.cfg'
#Set hostname
sudo hostnamectl set-hostname $user_hostname

apt-get update

#Install recquired packages
apt-get install opendkim opendkim-tools postfix-policyd-spf-python postfix-pcre

# Add user "postfix" to "opendkim" group
sudo usermod -G opendkim postfix

#Generate keys
sudo mkdir -p /etc/opendkim/keys

sudo chown -R opendkim:opendkim /etc/opendkim

sudo chmod  744 /etc/opendkim/keys

#Create Selector Key
mkdir /etc/opendkim/keys/$user_hostname

opendkim-genkey -b 2048 -d $user_hostname -D /etc/opendkim/keys/$user_hostname -s default -v

# Change Permission for the keys
chown opendkim:opendkim /etc/opendkim/keys/$user_hostname/default.private


#Edit Postfix.conf
sudo postconf -e 'inet_interfaces = loopback-only'


#Remove all the spaces and output the DKIM key
echo "----------------------------------------------------------------------------"
echo "Place the following output as the DKIM key in your DNS server"
cat /etc/opendkim/keys/$user_hostname/default.txt | awk -F'"' '{print $2}' | tr -d '[:space:]'
echo
echo "Add this as a new TXT record where the Record name is default._domainkey.$user_hostname"
echo File as is: /etc/opendkim/keys/$user_hostname/default.txt


echo


echo " Add a Mail service record if you havent already"
echo "10 mail.$user_hostname"
echo
echo "Add this as a new MX record where the Record name is $user_hostname"

echo " Add a SPF  record "
public_ip=$(curl -s ifconfig.me) && echo "v=spf1 ip4:$public_ip -all" 
echo
echo "Add this as a new TXT record where the Record name is $user_hostname"

echo " Add a DMARC  record "
echo "v=DMARC1; p=reject; rua=mailto: root@$user_hostname"
echo "Add this as a new TXT record where the Record name is _dmarc"
echo "----------------------------------------------------------------------------"

#Prompt user to press Enter
read -p "Press Enter to when done..."

#Edit config file for dkim
#Uncomment mode
sudo sed -i '/^#.*\bMode\b/s/^#//' /etc/opendkim.conf
#Uncomment Subdomains
sudo sed -i '/^#.*\bSubDomains\b/s/^#//' /etc/opendkim.conf

#Uncomment KeyFile
sudo sed -i '/^#.*\bKeyFile\b/s/^#//' /etc/opendkim.conf
#Uncomment Logwhy
sudo sed -i '/^#.*\LogWhy\b/s/^#//' /etc/opendkim.conf
#Uncomment Subdomain
sudo sed -i '/^#.*\bSubDomain\b/s/^#//' /etc/opendkim.conf
#Uncomment ExternaIgnoreList
sudo sed -i '/^#.*\bExternalIgnoreList\b/s/^#//' /etc/opendkim.conf
#Uncomment InternalHosts
sudo sed -i '/^#.*\bInternalHosts\b/s/^#//' /etc/opendkim.conf
# add domain to EOF

echo "AutoRestart            yes" | sudo tee -a /etc/opendkim.conf
echo "AutoRestartRate        10/1M" | sudo tee -a /etc/opendkim.conf
echo "Background             yes" | sudo tee -a /etc/opendkim.conf
echo "DNSTimeout             5" | sudo tee -a /etc/opendkim.conf
echo "SignatureAlgorithm     rsa-sha256" | sudo tee -a /etc/opendkim.conf
echo "KeyTable            refile:/etc/opendkim/key.table" | sudo tee -a /etc/opendkim.conf
echo "SigningTable     refile:/etc/opendkim/signing.table" | sudo tee -a /etc/opendkim.conf


#Add External and Internal hosts
echo "ExternalIgnoreList  /etc/opendkim/trusted.hosts" | sudo tee -a /etc/opendkim.conf
echo "InternalHosts       /etc/opendkim/trusted.hosts" | sudo tee -a /etc/opendkim.conf

#Edit signing.table
echo "*@$user_hostname default._domainkey.$user_hostname" | sudo tee /etc/opendkim/signing.table > /dev/null
echo "*@*.$user_hostname default._domainkey.$user_hostname" | sudo tee /etc/opendkim/signing.table > /dev/null

#Edit key.table
echo "default._domainkey.$user_hostname    $user_hostname:default:/etc/opendkim/keys/$user_hostname/default.private" | sudo tee /etc/opendkim/key.table > /dev/null

#Edit Trusted.hosts
echo -e "127.0.0.1\nlocalhost\nmail\nmail.$user_hostname\n$user_hostname"  | sudo tee /etc/opendkim/trusted.hosts  > /dev/null

# Configure the OpenDKIm socket location
sudo mkdir /var/spool/postfix/opendkim 
sudo chown opendkim:postfix /var/spool/postfix/opendkim 

sudo sed -i 's/^#\(Socket\s\+local:\/var\/spool\/postfix\/opendkim\/opendkim.sock\)/\1/' /etc/opendkim.conf

sudo sed -i 's|^SOCKET=local:$RUNDIR/opendkim.sock|SOCKET=local:/var/spool/postfix/opendkim/opendkim.sock|' /etc/default/opendkim

#Edit postfix configuration protocol

#set default action when message received
echo "milter_default_action = accept" | sudo tee -a /etc/postfix/main.cf
#Set protocol to be used when communicating with opendkim
echo "milter_protocol = 6" | sudo tee -a /etc/postfix/main.cf
#SMTPD_milters sets the list of milters postfix will use
echo "smtpd_milters = local:opendkim/opendkim.sock" | sudo tee -a /etc/postfix/main.cf
#specifies mail transmission for non smtp connections
echo "non_smtpd_milters = local:opendkim/opendkim.sock" | sudo tee -a /etc/postfix/main.cf


#Restart Postfix and DKIM
sudo systemctl restart opendkim 
sudo systemctl restart postfix 
systemctl start opendkim

#Check if  Postfix and DKIM services are running
systemctl status postfix 
systemctl status opendkim 