#!/bin/bash

#generate configd
function generate_configs() {
  #put in the env variables
  echo "Generating postfix configurations for ${SERVER_HOSTNAME}"
  envsubst '\$SERVER_HOSTNAME \$SERVER_IP' < src/postfix/main.cf > /etc/postfix/main.cf
  cp /etc/postfix/master.cf.orig /etc/postfix/master.cf
  envsubst '\$SERVER_HOSTNAME \$SERVER_IP' < src/opendkim/opendkim.conf > /etc/opendkim.conf

  # generate opendkim
  echo "Generating opendkim configurations for ${SERVER_HOSTNAME}"
  mkdir -p /etc/opendkim/keys
  chown -R opendkim:opendkim /etc/opendkim
  mkdir -p "/etc/opendkim/keys/${SERVER_HOSTNAME}"
  opendkim-genkey -b 2048 -d ${SERVER_HOSTNAME} -D /etc/opendkim/keys/${SERVER_HOSTNAME} -s default -v
  envsubst '\$SERVER_HOSTNAME \$SERVER_IP' < src/opendkim/trusted.hosts > /etc/opendkim/trusted.hosts 
  cp /etc/default/opendkim.orig /etc/default/opendkim
  echo 'SOCKET="inet:12301"' >> /etc/default/opendkim
  chown opendkim:opendkim /etc/opendkim/keys/${SERVER_HOSTNAME}/default.private

 
  # configure dovecot
  echo "Generating dovecot configurations for ${SERVER_HOSTNAME}"
  envsubst '\$SERVER_HOSTNAME \$SERVER_IP' < src/dovecot/dovecot.conf > /etc/dovecot/dovecot.conf

  # create a file marking the configuration as completed for this domain
  echo "All configurations generated for ${SERVER_HOSTNAME}"
}

function edit_signing_table (){
    #Edit signing.table
    echo "*@{$SERVER_HOSTNAME} default._domainkey.{$SERVER_HOSTNAME}" | sudo tee /etc/opendkim/signing.table > /dev/null
    echo "*@*.{$SERVER_HOSTNAME} default._domainkey.{$SERVER_HOSTNAME}" | sudo tee /etc/opendkim/signing.table > /dev/null

}
#Generate keys
function generate_dkim_keys () {
    mkdir -p /etc/opendkim/keys
    chown -R opendkim:opendkim /etc/opendkim
    chmod  744 /etc/opendkim/keys
    mkdir /etc/opendkim/keys/{$SERVER_HOSTNAME}
    #Create Selector Key
    opendkim-genkey -b 2048 -d {$SERVER_HOSTNAME} -D /etc/opendkim/keys/{$SERVER_HOSTNAME} -s default -v
    # Change Permission for the keys
    chown opendkim:opendkim /etc/opendkim/keys/{$SERVER_HOSTNAME}/default.private

}

# Check if running script is running as root
function check_root() {
    if [[ $(id -u) != "0" ]]; then
        echo "Error: Script must be run as root or with sudo!"
        exit 1
    fi
}

#Set cloud to false
function set_cloud_false () {
sudo bash -c 'awk "/^preserve_hostname: false\$/ {\$2=\"true\"} 1" /etc/cloud/cloud.cfg > /etc/cloud/cloud.cfg.tmp && mv /etc/cloud/cloud.cfg.tmp /etc/cloud/cloud.cfg'
}



#Edit Postfix.conf
function config_postfix(){
    postconf -e 'inet_interfaces = all'
    #set default action when message received
    postconf -e 'milter_default_action = accept'
    #Set protocol to be used when communicating with opendkim
    postconf -e 'milter_protocol = 6'
    #SMTPD_milters sets the list of milters postfix will use
    postconf -e 'smtpd_milters = local:opendkim/opendkim.sock'
    #specifies mail transmission for non smtp connections

    postconf -e 'non_smtpd_milters = local:opendkim/opendkim.sock'
    postconf -e 'smtpd_sasl_type = dovecot'
    postconf -e 'smtpd_sasl_auth_enable = yes'
    postconf -e 'smtpd_recipient_restrictions = permit_sasl_authenticated,permit_mynetworks,reject_unauth_destination'
    postconf -e 'non_smtpd_milters = local:opendkim/opendkim.sock'
}

# Edit config file for dkim
function config_opendkim(){
    # Uncomment Mode
    sed -i '/^#.*\bMode\b/s/^#//' /etc/opendkim.conf
    # Uncomment Subdomains
    sed -i '/^#.*\bSubDomains\b/s/^#//' /etc/opendkim.conf
    # Uncomment KeyFile
    sed -i '/^#.*\bKeyFile\b/s/^#//' /etc/opendkim.conf
    # Uncomment Logwhy
    sed -i '/^#.*\LogWhy\b/s/^#//' /etc/opendkim.conf
    # Uncomment Subdomain
    sed -i '/^#.*\bSubDomain\b/s/^#//' /etc/opendkim.conf
    # Uncomment ExternaIgnoreList
    sed -i '/^#.*\bExternalIgnoreList\b/s/^#//' /etc/opendkim.conf
    # Uncomment InternalHosts
    sed -i '/^#.*\bInternalHosts\b/s/^#//' /etc/opendkim.conf
    
    # restart if opendkim stops
    echo "AutoRestart            yes" |  tee -a /etc/opendkim.conf
    echo "AutoRestartRate        10/1M" |  tee -a /etc/opendkim.conf
    
    # run in background
    echo "Background             yes" |  tee -a /etc/opendkim.conf
    
    echo "DNSTimeout             5" |  tee -a /etc/opendkim.conf
    echo "SignatureAlgorithm     rsa-sha256" |  tee -a /etc/opendkim.conf
    
    # specify key tables and signing table locations
    echo "KeyTable            refile:/etc/opendkim/key.table" |  tee -a /etc/opendkim.conf
    echo "SigningTable     refile:/etc/opendkim/signing.table" |  tee -a /etc/opendkim.conf

    # specify the file containing a list of hosts
    echo "ExternalIgnoreList  /etc/opendkim/trusted.hosts" |  tee -a /etc/opendkim.conf
    echo "InternalHosts       /etc/opendkim/trusted.hosts" |  tee -a /etc/opendkim.conf
    #Edit key.table
    echo "default._domainkey.{$SERVER_HOSTNAME}    {$SERVER_HOSTNAME}:default:/etc/opendkim/keys/{$SERVER_HOSTNAME}/default.private" | sudo tee /etc/opendkim/key.table > /dev/null

    #Edit Trusted.hosts
    echo -e "127.0.0.1\nlocalhost\nmail\nmail.{$SERVER_HOSTNAME}\n{$SERVER_HOSTNAME}"  | sudo tee /etc/opendkim/trusted.hosts  > /dev/null

    # Configure the OpenDKIm socket location
    mkdir /var/spool/postfix/opendkim 
    chown opendkim:postfix /var/spool/postfix/opendkim 

    sed -i 's/^#\(Socket\s\+local:\/var\/spool\/postfix\/opendkim\/opendkim.sock\)/\1/' /etc/opendkim.conf
    sed -i 's|^SOCKET=local:$RUNDIR/opendkim.sock|SOCKET=local:/var/spool/postfix/opendkim/opendkim.sock|' /etc/default/opendkim
}



function config_dovecot (){
    # configure dovecot to use sasl
    sed -i '/^service auth {/a \
        unix_listener /var/spool/postfix/private/auth { mode = 0666 }' /etc/dovecot/conf.d/10-master.conf
        
    # configure login authentication 
    sed -i '/^auth_mechanisms = plain/ s/$/ login/' /etc/dovecot/conf.d/10-auth.conf
}

function restart_services()
{
    systemctl restart opendkim postfix
    service dovecot restart
    #Restart Postfix and DKIM
    systemctl start opendkim
}

function test_config () {
    # test if localhost on port 25 works
   if echo "ehlo localhost" | telnet localhost 25 |   grep -q "250-AUTH PLAIN LOGIN" ; then
        echo "Test passed: Set up succesful"
    else
        echo "Test failed: Set up failed"
    fi

    # test if postfix service is active
    if systemctl is-active --quiet postfix; then
        echo "Postfix is running."
    else
        echo "Postfix is not running."
    fi

    # test if opendkim service is active
    if systemctl is-active --quiet opendkim; then
        echo "opendkim is running."
    else
        echo "opendkim is not running."
    fi
}

function output_keys (){
    echo "-=-=-=-=--=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-==-=-=-"
    echo "Place the following output as the DKIM key in your DNS server, note that formatting may differ depending on DNS provider"
    cat /etc/opendkim/keys/{$SERVER_HOSTNAME}/default.txt | awk -F'"' '{print $2}' | tr -d '[:space:]'
    echo "Add this as a new TXT record where the Record name is default._domainkey.{$SERVER_HOSTNAME}"
    echo "File as is:"
    cat /etc/opendkim/keys/{$SERVER_HOSTNAME}/default.txt

    echo

    echo "Place the following output as the DMARC key in your DNS server"
    echo "v=DMARC1; p=reject; rua=mailto:user@{$SERVER_HOSTNAME}"
    echo "Add this as a new TXT record where the Record name is _dmarc.{$SERVER_HOSTNAME}"
    echo

    echo "Place the following output as the MX (Mailserver) value in your DNS server"
    echo "10 {$SERVER_HOSTNAME}"
    echo "Add this as a new MX record where the Record name is {$SERVER_HOSTNAME}"

    echo "Add an SPF record"
    public_ip=$(curl -s ifconfig.me) && echo "v=spf1 mx $SERVER_IP -all" 
    echo "Add this as a new TXT record where the Record name is {$SERVER_HOSTNAME}"

    echo "-=-=-=-=--=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-==-=-=-"
    echo "Press Enter to continue with script............."
    read -r
}

function generate_users() {
  echo "Generating users and passwords:"
  echo "--------------------------------------------"
  while IFS=" " read -r username password || [ -n "$username" ]; do
    if [ -z "$password" ]; then
      password=$(diceware -d-)
      echo -e "$username\t$password"
    else
      echo -e "$username\t<set by secrets file>"
    fi
    adduser "$username" --quiet --disabled-password --shell /usr/sbin/nologin --gecos "" --force-badname || true
    echo "$username:$password" | chpasswd || true
  done
  echo "--------------------------------------------"
}

if [ "$1" = 'postfix' ]; then
  echo "Starting mail server with:"
  echo "  SERVER_HOSTNAME=${SERVER_HOSTNAME}"
  echo "  RELAY_IP=${RELAY_IP}"

  # check to see if the configuration was completed for this domain
  if [[ ! -f conf_gen_done.txt ]] || [[ $(< conf_gen_done.txt) != "${SERVER_HOSTNAME}" ]]; then
    generate_configs
    echo "${SERVER_HOSTNAME}" > conf_gen_done.txt
  else
    echo "Configurations already generated for ${SERVER_HOSTNAME}, preserving."
  fi

  # generate the users from the secrets
  grep -v '^#\|^$' /run/secrets/users.txt | generate_users

  # postfix needs fresh copies of files in its chroot jail
  cp /etc/{hosts,localtime,nsswitch.conf,resolv.conf,services} /var/spool/postfix/etc/

  echo "DKIM DNS entry:"
    output_keys

  opendmarc
  opendkim
  dovecot
  exec "$@"
fi

exec "$@"